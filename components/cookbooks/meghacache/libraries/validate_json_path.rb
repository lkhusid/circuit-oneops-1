require 'json'

def deep_fetch(node, *args)
    path_str = args.collect
    value = "node"

    path_str.each do |path_key|

        raw_element = path_key
        sanitized_element = raw_element

        if raw_element.include?('.') then
            sanitized_element = raw_element.split('.')[0]
            Chef::Log.info "deep_fetch: sanitized_element = #{sanitized_element}"
        end

        validation_expr = ".key?('#{sanitized_element}')"

        begin
            eval("#{value}#{validation_expr}")
            final_expr = value.concat(".#{raw_element}")
            Chef::Log.info "deep_fetch: #{validation_expr} : #{final_expr}"

        rescue Exception
            Chef::Log.info "ERROR: deep_fetch: #{value}#{validation_expr} check failed in workorder"
            return 1
        end
    end

    return 0
end
