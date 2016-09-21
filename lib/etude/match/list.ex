defimpl Etude.Matchable, for: List do
  alias Etude.Match.{Literal}

  def compile([]) do
    Literal.compile([])
  end
  def compile(l) do
    l_f = c(l, [], :compile)
    fn(v, b) ->
      v
      |> Etude.Future.to_term()
      |> Etude.Future.chain(fn
        (v) when is_list(v) ->
          compare(l_f, v, b, [])
        (v) ->
          Etude.Future.reject({l, v})
      end)
    end
  end

  defp compare([], [], _, acc) do
    acc
    |> :lists.reverse()
    |> Etude.Future.parallel()
  end
  defp compare([a_h | a_t], [b_h | b_t], b, acc) do
    f = a_h.(b_h, b)
    compare(a_t, b_t, b, [f | acc])
  end
  defp compare(a, b, bindings, acc) when is_function(a, 2) do
    f = a.(b, bindings)
    compare([], [], bindings, [f | acc])
  end
  defp compare(a, b, _, _acc) do
    Etude.Future.reject({a, b})
  end

  def compile_body([]) do
    Literal.compile_body([])
  end
  def compile_body(l) do
    l = c(l, [], :compile_body)
    fn(b) ->
      for i <- l do
        i.(b)
      end
    end
  end

  defp c([], acc, _fun) do
    :lists.reverse(acc)
  end
  defp c([head | tail], acc, fun) do
    h = apply(@protocol, fun, [head])
    c(tail, [h | acc], fun)
  end
  defp c(tail, acc, fun) do
    t = apply(@protocol, fun, [tail])
    reverse_cons(acc, t)
  end

  defp reverse_cons([], acc) do
    acc
  end
  defp reverse_cons([head | tail], acc) do
    reverse_cons(tail, [head | acc])
  end
end
