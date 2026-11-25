require_relative '../test_helper'

module RedmicaS3
  class ConnectionTest < ActiveSupport::TestCase
    setup do
      @original_conn = Connection.class_variable_get(:@@conn)
      Connection.class_variable_set(:@@conn, nil)
    end

    teardown do
      Connection.class_variable_set(:@@conn, @original_conn)
    end

    test 'establish_connection passes static credentials when both keys are set' do
      stub_s3_options(access_key_id: 'AKIAEXAMPLE', secret_access_key: 'secret')

      assert_resource_created_with(access_key_id: 'AKIAEXAMPLE', secret_access_key: 'secret')
    end

    test 'establish_connection passes session_token along with static credentials' do
      stub_s3_options(access_key_id: 'ASIAEXAMPLE', secret_access_key: 'secret', session_token: 'token')

      assert_resource_created_with(access_key_id: 'ASIAEXAMPLE', secret_access_key: 'secret', session_token: 'token')
    end

    test 'establish_connection passes no credentials when both keys are empty' do
      stub_s3_options(access_key_id: nil, secret_access_key: nil)

      assert_resource_created_with({})
    end

    test 'establish_connection treats blank strings as empty keys' do
      stub_s3_options(access_key_id: '', secret_access_key: '  ', session_token: '')

      assert_resource_created_with({})
    end

    test 'establish_connection ignores session_token without static credentials' do
      stub_s3_options(access_key_id: nil, secret_access_key: nil, session_token: 'token')

      assert_resource_created_with({})
    end

    test 'establish_connection raises when only one key is set' do
      [
        {access_key_id: 'AKIAEXAMPLE', secret_access_key: nil},
        {access_key_id: '', secret_access_key: 'secret'}
      ].each do |options|
        stub_s3_options(options)
        Aws::S3::Resource.expects(:new).never

        error = assert_raises(ArgumentError) { Connection.send(:establish_connection) }
        assert_match(/access_key_id and secret_access_key/, error.message)
      end
    end

    test 'establish_connection passes region with the credential options' do
      stub_s3_options(access_key_id: nil, secret_access_key: nil, region: 'ap-northeast-1')

      assert_resource_created_with(region: 'ap-northeast-1')
    end

    private

    def stub_s3_options(options)
      Connection.stubs(:s3_options).returns({bucket: 'redmine-bucket'}.merge(options))
    end

    def assert_resource_created_with(expected)
      resource = stub('resource')
      Aws::S3::Resource.expects(:new).with(expected).returns(resource)

      assert_same resource, Connection.send(:establish_connection)
    end
  end
end
