require 'aws-sdk-resources'

module Prpr
  module Action
    module CodePipeline
      class Deploy < Base
        def call
          if name = deployment_group_name(event)
            create_deployment(name, deploy_commit)
            # AWS側でCodePipeline開始を通知するので、prprからは通知を送らない
          end
        end

        private

        def deploy_commit
          event.after
        end

        def deployment_group_name(event)
          if event.ref =~ %r(#{prefix}/(.*)) and !event.forced
            env.format(:code_deploy_group, { branch: $1 })
          else
            nil
          end
        end

        def aws
          @aws ||= ::Aws::CodePipeline::Client.new(
            region: env[:code_deploy_region] || 'ap-northeast-1',
            access_key_id: env[:code_deploy_aws_key],
            secret_access_key: env[:code_deploy_aws_secret],
          )
        end

        def create_deployment(pipeline_name, commit_id)
          aws.start_pipeline_execution({
            name: pipeline_name
          })
        end

        def message(deployment)
          Prpr::Publisher::Message.new(
            body: deployment.pipeline_execution_id,
            from: { login: 'aws' },
            room: env[:code_deploy_room])
        end

        def prefix
          env[:code_deploy_prefix] || 'deployment'
        end
      end
    end
  end
end
