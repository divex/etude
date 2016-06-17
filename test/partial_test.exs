defmodule EtudeTest.Partial do
  use EtudeTestHelper

  etudetest "should call a partial", [
    render: [
      %Partial{
        module: __MODULE__, function: :user
      }
    ],
    user: [
      %{"name" => "Robert"}
    ]
  ], %{"name" => "Robert"}

  etudetest "should dynamically call partials", [
    render: [
      %Assign{name: :mod, expression: __MODULE__},
      %Assign{name: :func, expression: :partial},
      %Partial{module: %Var{name: :mod}, function: %Var{name: :func}}
    ],
    partial: [
      "It works!"
    ]
  ], "It works!"

  etudetest "should call a partial with a different scope", [
    render: [
      %Assign{name: :foo, expression: "Parent"},
      {
        %Var{name: :foo},
        %Partial{module: __MODULE__, function: :partial1}
      }
    ],
    partial1: [
      %Assign{name: :foo, expression: "Child 1"},
      {
        %Var{name: :foo},
        %Partial{module: __MODULE__, function: :partial2}
      }
    ],
    partial2: [
      %Assign{name: :foo, expression: "Child 2"},
      %Var{name: :foo}
    ]
  ], {"Parent", {"Child 1", "Child 2"}}

  etudetest "should render a partial inside a comprehension", [
    render: [
      %Comprehension{
        collection: [1,2,3,4],
        expression: %Partial{module: __MODULE__, function: :partial}
      }
    ],
    partial: [
      "HI!"
    ]
  ], ["HI!", "HI!", "HI!", "HI!"]

  etudetest "should render a partial inside a comprehension with props", [
    render: [
      %Comprehension{
        collection: ["Joe", "Robert", "Mike"],
        value: %Assign{name: :name},
        expression: %Partial{
          module: __MODULE__, function: :partial,
          props: %{name: %Var{name: :name}}
        },
      }
    ],
    partial: [
      %Assign{name: :name, expression: %Prop{name: :name}},
      ["Hello, ", %Var{name: :name}]
    ]
  ], [["Hello, ", "Joe"], ["Hello, ", "Robert"], ["Hello, ", "Mike"]]

  etudetest "should pass props", [
    render: [
      %Partial{
        module: __MODULE__, function: :partial,
        props: %{
          0 => "World"
        }
      }
    ],
    partial: [
      [
        "Hello, ",
        %Prop{name: 0}
      ]
    ]
  ], ["Hello, ", "World"]

  etudetest "should pass a lazy props", [
    render: [
      %Partial{
        module: __MODULE__, function: :partial,
        props: %{
          0 => :math,
          1 => :add,
          2 => %Call{
            module: :math, function: :add,
            arguments: [
              1,
              2
            ]
          }
        }
      }
    ],
    partial: [
      [
        %Prop{name: 0},
        %Prop{name: 1},
        %Prop{name: 2}
      ]
    ]
  ], [:math, :add, 3]

  etudetest "should support props inside comprehensions", [
    render: [
      %Assign{name: :name, expression: "Robert"},
      %Partial{module: __MODULE__, function: :partial, props: %{name: %Var{name: :name}}}
    ],
    partial: [
      %Comprehension{
        collection: ["facebook", "twitter", "linkedin"],
        value: %Assign{name: :network},
        expression: %{
          network: %Var{name: :network},
          name: %Prop{name: :name}
        }
      }
    ]
  ], [%{network: "facebook", name: "Robert"},
      %{network: "twitter", name: "Robert"},
      %{network: "linkedin", name: "Robert"}]

  test "apply_partial without arguments" do
    ast = parse apply_partial(Module, :func)

    assert ast == %Partial{
      function: :func,
      module: Module,
      props: %{}
    }
  end

  test "apply_partial with dynamic function" do
    ast = parse apply_partial(Module, func)

    assert ast == %Partial{
      function: %Var{name: :func},
      module: Module,
      props: %{}
    }
  end

  test "apply_partial with dynamic module" do
    ast = parse apply_partial(module, func)

    assert ast == %Partial{
      function: %Var{name: :func},
      module: %Var{name: :module},
      props: %{}
    }
  end

  test "apply_partial with one fixed prop" do
    ast = parse apply_partial(Module, :func, prop: :value)

    assert ast == %Partial{
      function: :func,
      module: Module,
      props: %{prop: :value}
    }
  end

  test "apply_partial with one prop" do
    ast = parse apply_partial(Module, :func, prop: value)

    assert ast == %Partial{
      function: :func,
      module: Module,
      props: %{prop: %Var{name: :value}}
    }
  end

  test "apply_partial with multiple props" do
    ast = parse apply_partial(Module, :func, [prop1: value1, prop2: value2])

    assert ast == %Partial{
      function: :func,
      module: Module,
      props: %{
        prop1: %Var{name: :value1},
        prop2: %Var{name: :value2}
      }
    }
  end

  test "apply_partial with multiple props as last keyword argument" do
    ast = parse apply_partial(Module, :func, prop1: value1, prop2: value2)

    assert ast == %Partial{
      function: :func,
      module: Module,
      props: %{
        prop1: %Var{name: :value1},
        prop2: %Var{name: :value2}
      }
    }
  end
end