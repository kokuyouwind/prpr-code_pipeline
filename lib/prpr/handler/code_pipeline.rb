module Prpr
    module Handler
      class CodePipeline < Base
        handle Event::Push do
          Action::CodePipeline::Deploy.new(event).call
        end
      end
    end
end
