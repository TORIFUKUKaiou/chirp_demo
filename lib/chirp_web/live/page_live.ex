defmodule ChirpWeb.PageLive do
  use ChirpWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    if info = get_connect_info(socket) do
      IO.inspect info
      ip =
        if Enum.count(info.x_headers) > 0 do
          Enum.find(info.x_headers, {"x-forwarded-for", "127.0.0.1"}, fn {key, _value} -> key == "x-forwarded-for" end)
          |> elem(1)
        else
          info.peer_data.address
          |> Tuple.to_list()
          |> Enum.join(if tuple_size(info.peer_data.address) == 4, do: ".", else: ":")
        end

      {:ok, assign(socket, query: "", results: %{}, ip: ip)}
    else
      {:ok, assign(socket, query: "", results: %{}, ip: nil)}
    end
  end

  @impl true
  def handle_event("suggest", %{"q" => query}, socket) do
    {:noreply, assign(socket, results: search(query), query: query)}
  end

  @impl true
  def handle_event("search", %{"q" => query}, socket) do
    case search(query) do
      %{^query => vsn} ->
        {:noreply, redirect(socket, external: "https://hexdocs.pm/#{query}/#{vsn}")}

      _ ->
        {:noreply,
         socket
         |> put_flash(:error, "No dependencies found matching \"#{query}\"")
         |> assign(results: %{}, query: query)}
    end
  end

  defp search(query) do
    if not ChirpWeb.Endpoint.config(:code_reloader) do
      raise "action disabled when not in development"
    end

    for {app, desc, vsn} <- Application.started_applications(),
        app = to_string(app),
        String.starts_with?(app, query) and not List.starts_with?(desc, ~c"ERTS"),
        into: %{},
        do: {app, vsn}
  end
end
