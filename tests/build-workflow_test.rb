require 'minitest/autorun'
require 'yaml'
require 'open3'
require 'tmpdir'

class BuildWorkflowTest < Minitest::Test
  def setup
    @caller = YAML.load_file('.github/workflows/build-images.yml')
    @job = @caller.fetch('jobs').fetch('build-scan-push')
  end

  def test_existing_variants_and_latest_owners
    expected = [
      ['eclipse-temurin', 'images/java/eclipse-temurin', 'Dockerfile.java21', '21-jre-jammy', false],
      ['eclipse-temurin', 'images/java/eclipse-temurin', 'Dockerfile.java25', '25-jre-jammy', true],
      ['distroless-java', 'images/java/distroless', 'Dockerfile.java21', '21-jre', false],
      ['distroless-java', 'images/java/distroless', 'Dockerfile.java25', '25-jre', true],
      ['node', 'images/node/alpine', 'Dockerfile', '24-alpine', false],
      ['node', 'images/node/alpine', 'Dockerfile.node26', '26-alpine', false],
      ['node', 'images/node/alpine-runtime', 'Dockerfile', '24-alpine-runtime', true],
      ['node', 'images/node/alpine-runtime', 'Dockerfile.node26', '26-alpine-runtime', false],
      ['distroless-node', 'images/node/distroless', 'Dockerfile', '24', true],
      ['distroless-node', 'images/node/distroless', 'Dockerfile.node26', '26', false],
      ['python', 'images/python/alpine', 'Dockerfile', 'python3.13-alpine', true],
    ]
    rows = @job.fetch('strategy').fetch('matrix').fetch('include')
    actual = rows.map do |row|
      [row.fetch('image_name'), row.fetch('context'), File.basename(row.fetch('dockerfile')),
       row.fetch('tag_prefix').to_s, row.fetch('publish_latest')]
    end
    assert_equal expected, actual
    assert_equal 11, rows.map { |row| [row['image_name'], row['tag_prefix']] }.uniq.length
    rows.each { |row| assert File.file?(row.fetch('dockerfile')) }
  end

  def test_existing_events_and_cancellation
    events = @caller.fetch('on', @caller[true])
    assert_equal({ 'branches' => ['main'] }, events.fetch('push'))
    assert_equal [{ 'cron' => '0 5 * * 1-5' }], events.fetch('schedule')
    assert_equal %w[pull_request push schedule workflow_dispatch], events.keys.sort
    assert_equal({ 'group' => '${{ github.workflow }}-${{ github.ref }}',
                   'cancel-in-progress' => true }, @caller.fetch('concurrency'))
    assert_equal false, @job.fetch('strategy').fetch('fail-fast')
  end

  def test_reusable_boundary
    assert_equal './.github/workflows/build-docker-image.yml', @job.fetch('uses')
    workflow = YAML.load_file('.github/workflows/build-docker-image.yml')
    interface = workflow.fetch('on', workflow[true]).fetch('workflow_call')
    %w[image_name flavour context dockerfile tag_prefix registry].each do |name|
      assert_equal 'string', interface.fetch('inputs').fetch(name).fetch('type')
      assert_equal true, interface.fetch('inputs').fetch(name).fetch('required')
    end
    assert_equal 'boolean', interface.fetch('inputs').fetch('publish_latest').fetch('type')
    assert_equal true, interface.fetch('inputs').fetch('publish_latest').fetch('required')
    %w[image_name flavour context dockerfile tag_prefix publish_latest].each do |name|
      assert_equal "${{ matrix.#{name} }}", @job.fetch('with').fetch(name)
    end
    assert_equal 'ghcr.io', @job.fetch('with').fetch('registry')
    assert_equal %w[HMPPS_SNYK_API_KEY HMPPS_SRE_SLACK_BOT_TOKEN],
                 @job.fetch('secrets').keys.sort
    @job.fetch('secrets').each do |name, value|
      assert_equal "${{ secrets.#{name} }}", value
      assert_equal({ 'required' => false }, interface.fetch('secrets').fetch(name))
    end
    refute interface.fetch('secrets').key?('GITHUB_TOKEN')
    assert_equal({ 'contents' => 'read', 'packages' => 'write', 'security-events' => 'write' },
                 @job.fetch('permissions'))
    assert_equal @job.fetch('permissions'), workflow.fetch('jobs').fetch('build').fetch('permissions')
    refute workflow.key?('concurrency')
    @job.fetch('strategy').fetch('matrix').fetch('include').each do |row|
      assert_kind_of String, row.fetch('tag_prefix')
      assert_includes %w[build runtime], row.fetch('flavour')
    end
  end

  def test_build_scan_and_tag_contract
    workflow = YAML.load_file('.github/workflows/build-docker-image.yml')
    job = workflow.fetch('jobs').fetch('build')
    assert_equal 'ubuntu-latest', job.fetch('runs-on')
    assert_equal 20, job.fetch('timeout-minutes')
    steps = job.fetch('steps')
    metadata = steps.find { |step| step['id'] == 'meta' }.fetch('with')
    assert_equal '${{ inputs.registry }}/${{ github.repository_owner }}/hmpps-${{ inputs.image_name }}',
                 metadata.fetch('images')
    assert_equal "latest=false\n", metadata.fetch('flavor')
    rules = metadata.fetch('tags').lines.map(&:strip).reject { |line| line.start_with?('#') }
    assert_equal [
      "type=schedule,pattern={{date 'YYYYMMDD'}},prefix=${{ inputs.tag_prefix }}-",
      'type=ref,event=branch,prefix=${{ inputs.tag_prefix }}-',
      'type=ref,event=tag,prefix=${{ inputs.tag_prefix }}-',
      'type=ref,event=pr,prefix=${{ inputs.tag_prefix }}-',
      'type=sha,prefix=${{ inputs.tag_prefix }}-',
      'type=raw,value=${{ inputs.tag_prefix }}',
      'type=raw,value=latest,enable=${{ inputs.publish_latest }}',
    ], rules
    build = steps.find { |step| step['name'] == 'Build and push container image' }.fetch('with')
    publish = "github.ref == 'refs/heads/main' || github.event_name == 'schedule'"
    assert_equal "${{ #{publish} }}", build.fetch('push')
    assert_equal "${{ !(#{publish}) }}", build.fetch('load')
    assert_equal "${{ (#{publish}) && 'linux/amd64,linux/arm64' || 'linux/amd64' }}",
                 build.fetch('platforms')
    assert_equal "${{ (#{publish}) && steps.meta.outputs.tags || format('snyk-scan:{0}-{1}', inputs.image_name, inputs.tag_prefix) }}",
                 build.fetch('tags')
    assert_equal 'type=gha', build.fetch('cache-from')
    assert_equal 'type=gha,mode=max', build.fetch('cache-to')
    assert_equal 'security-upgrades', build.fetch('no-cache-filters')
    scan = steps.find { |step| step['id'] == 'snyk-scan' }
    assert_equal '${{ steps.snyk_image.outputs.image_ref }}', scan.fetch('with').fetch('image_ref')
    assert_equal 'high', scan.fetch('with').fetch('severity')
    resolve = steps.find { |step| step['id'] == 'snyk_image' }.fetch('run')
    assert_includes resolve, 'hmpps-${{ inputs.image_name }}:${{ inputs.tag_prefix }}'
    assert_includes resolve, 'snyk-scan:${{ inputs.image_name }}-${{ inputs.tag_prefix }}'
    notification = steps.find { |step| step['name'] == 'Snyk slack notification' }
    assert_equal "(failure() || steps.snyk-scan.outcome == 'failure' || fromJSON(steps.snyk-scan.outputs.results_count || '0') > 0) && (vars.SECURITY_ALERTS_SLACK_CHANNEL_ID || 'NO_SLACK') != 'NO_SLACK'",
                 notification.fetch('if')
    refute job.key?('continue-on-error')
  end

  def test_scan_references_for_each_variant_and_event
    workflow = YAML.load_file('.github/workflows/build-docker-image.yml')
    steps = workflow.fetch('jobs').fetch('build').fetch('steps')
    script = steps.find { |step| step['id'] == 'snyk_image' }.fetch('run')
    [
      ['push', 'refs/heads/main', true],
      ['schedule', 'refs/heads/main', true],
      ['pull_request', 'refs/pull/123/merge', false],
      ['workflow_dispatch', 'refs/heads/main', true],
      ['workflow_dispatch', 'refs/heads/feature', false],
    ].each do |event, ref, publish|
      @job.fetch('strategy').fetch('matrix').fetch('include').each do |row|
        values = {
          'github.ref' => ref, 'github.event_name' => event,
          'github.repository_owner' => 'ministryofjustice',
          'inputs.registry' => 'ghcr.io', 'inputs.image_name' => row['image_name'],
          'inputs.tag_prefix' => row['tag_prefix'].to_s,
        }
        command = script.gsub(/\$\{\{ ([^}]+) \}\}/) { values.fetch(Regexp.last_match(1)) }
        Dir.mktmpdir('workflow-contract-') do |directory|
          output = File.join(directory, 'output')
          stdout, stderr, status = Open3.capture3({ 'GITHUB_OUTPUT' => output }, 'bash', '-e', '-c', command)
          assert status.success?, "#{event}/#{row['tag_prefix']}: #{stdout}#{stderr}"
          image = if publish
                    "ghcr.io/ministryofjustice/hmpps-#{row['image_name']}:#{row['tag_prefix']}"
                  else
                    "snyk-scan:#{row['image_name']}-#{row['tag_prefix']}"
                  end
          assert_equal "image_ref=#{image}\n", File.read(output)
        end
      end
    end
  end
end
