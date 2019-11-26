defmodule Surface.Translator.ComponentTranslator do
  alias Surface.Translator
  alias Surface.Translator.Directive
  alias Surface.Properties
  import Surface.Translator.ComponentTranslatorUtils

  def translate(node, caller) do
    {mod_str, attributes, children, %{module: mod}} = node
    {data_children, children} = split_data_children(children)
    {directives, attributes} = Directive.pop_directives(attributes)

    # TODO: Find a better approach for this. For now, if there's any
    # DataComponent and the rest of children are blank, we remove them.
    children =
      if data_children != %{} && String.trim(IO.iodata_to_binary(children)) == "" do
        []
      else
        children
      end

    ######

    {children_contents, children_attributes} = translate_children(directives, children, caller)

    {children_groups_contents, children_groups_attributes} =
      translate_children_groups(mod, attributes, data_children, caller)

    translated_props = Properties.translate_attributes(attributes, mod, mod_str, caller)
    all_attributes = children_attributes ++ children_groups_attributes ++ attributes
    all_translated_props = Properties.translate_attributes(all_attributes, mod, mod_str, caller)

    [
      Directive.maybe_add_directives_begin(directives),
      maybe_add_context_begin(mod, mod_str, translated_props),
      Translator.translate(children_groups_contents, caller),
      Translator.translate(children_contents, caller),
      add_require(mod_str),
      add_render_call("component", [mod_str, all_translated_props], false),
      maybe_add_context_end(mod, mod_str, translated_props),
      Directive.maybe_add_directives_end(directives)
    ]
  end
end

