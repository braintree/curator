<% module_namespacing do -%>
class <%= class_name %>
  include Curator::Model
<% unless attributes.empty? -%>
  attr_accessor <%= attributes.map {|a| ":#{a.name}" }.join(', ') %>
<% end -%>
end
<% end -%>
