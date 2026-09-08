; Zig definitions and direct/member calls. Container types are named by their const declaration.

(function_declaration
  name: (identifier) @name) @definition.function

(test_declaration
  (string) @name) @definition.function

(variable_declaration
  (identifier) @name
  (struct_declaration)) @definition.type

(variable_declaration
  (identifier) @name
  (enum_declaration)) @definition.type

(variable_declaration
  (identifier) @name
  (union_declaration)) @definition.type

(variable_declaration
  (identifier) @name
  (error_set_declaration)) @definition.type

(call_expression
  function: (identifier) @name) @reference.call

(call_expression
  function: (field_expression
    member: (identifier) @name)) @reference.call
