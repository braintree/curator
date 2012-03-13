<% module_namespacing do -%>
class <%= class_name %>Repository
  include Curator::Repository
<% unless attributes.empty? -%>
  indexed_fields <%= attributes.map {|a| ":#{a.name}" }.join(', ') %>
<% end -%>
end
<% end -%>
