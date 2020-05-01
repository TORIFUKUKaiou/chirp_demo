# Would you please refer to https://qiita.com/piacerex/items/9b9e2fc59b74b529b66b ?
defmodule ChirpWeb.BoxesLive do
  use ChirpWeb, :live_view

  def mount(_params, _session, socket) do
    if connected?(socket), do: queue_animate(socket)

    {:ok, assign(socket, time: 0, boxes: boxes(0))}
  end

  def queue_animate(socket), do: Process.send_after(self(), :animate, trunc(1000 / 60))

  def handle_info(:animate, socket) do
    queue_animate(socket)
    next_time = Map.get(socket.assigns, :time, 0) + 1

    {:noreply, assign(socket, time: next_time, boxes: boxes(next_time))}
  end

  defp boxes(time) do
    count = 10
    shift = 100 / (count + 1)

    0..count
    |> Enum.map(
      &%{
        x: shift * &1,
        y: 0,
        rotation: rem(time, 360),
        translate_x: :math.sin(time / 10) * 25,
        translate_y: :math.cos(time / 10) * 25
      }
    )
  end
end
