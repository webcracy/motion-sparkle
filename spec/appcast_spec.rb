# frozen_string_literal: true

require_relative 'spec_utils'

describe 'Appcast' do
  describe 'arguments' do
    before do
      @appcast = Motion::Project::Sparkle::Appcast.new(nil)
    end

    it 'defaults to empty' do
      args = @appcast.prepare_args

      expect(args).to eq ['--account=ed25519']
    end

    it 'sets all command line options' do
      expected_results = [
        '--account=test1',
        '--ed-key-file=test2',
        '--download-url-prefix=test3',
        '--release-notes-url-prefix=test4',
        '--full-release-notes-url=test5',
        '--link=test6',
        '--versions=test7',
        '--maximum-deltas=test8',
        '--delta-compression=test9',
        '--delta-compression-level=test10',
        '--channel=test11',
        '--major-version=test12',
        '--ignore-skipped-upgrades-below-version=test13',
        '--phased-rollout-interval=test14',
        '--critical-update-version=test15',
        '--informational-update-versions=test16',
        '-o=test17'
      ]

      @appcast.process_option?(:account, 'test1')
      @appcast.process_option?(:private_ed_key_file, 'test2')
      @appcast.process_option?(:download_url_prefix, 'test3')
      @appcast.process_option?(:release_notes_url_prefix, 'test4')
      @appcast.process_option?(:full_release_notes_url, 'test5')
      @appcast.process_option?(:link, 'test6')
      @appcast.process_option?(:versions, 'test7')
      @appcast.process_option?(:maximum_deltas, 'test8')
      @appcast.process_option?(:delta_compression, 'test9')
      @appcast.process_option?(:delta_compression_level, 'test10')
      @appcast.process_option?(:channel, 'test11')
      @appcast.process_option?(:major_version, 'test12')
      @appcast.process_option?(:ignore_skipped_upgrades_below_version, 'test13')
      @appcast.process_option?(:phased_rollout_interval, 'test14')
      @appcast.process_option?(:critical_update_version, 'test15')
      @appcast.process_option?(:informational_update_versions, 'test16')
      @appcast.process_option?(:output_path, 'test17')
      args = @appcast.prepare_args

      expect(args).to match_array expected_results
    end
  end
end
