defmodule TreechatWeb.ChatMessageLive.FormComponent do
  use TreechatWeb, :live_component
  require Logger

  alias Treechat.MessageTree

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle>Use this form to manage chat_message records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="chat_message-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <!--<.inputs_for :let={author_form} field={@form[:author]}>
          <.input field={author_form[:email]} type="text" />
        </.inputs_for>-->
        <.input field={@form[:author]} type="id" label="author id" />
        <.input field={@form[:content]} type="text" label="Content" />
        <:actions>
          <.button phx-disable-with="Saving...">Save Chat message</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end
  # removed this but the author is there, just not sure how to render it in the template.
  # <span>author: <%={@chat_message.author.email}%></span>

  @impl true
  def update(%{chat_message: chat_message} = assigns, socket) do
    changeset = MessageTree.change_chat_message(chat_message)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"chat_message" => chat_message_params}, socket) do
    changeset =
      socket.assigns.chat_message
      |> MessageTree.change_chat_message(chat_message_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"chat_message" => chat_message_params}, socket) do
    Logger.debug "handle_event save assigns: #{inspect(socket.assigns)}"
    save_chat_message(socket, socket.assigns.action, chat_message_params)
  end

  defp save_chat_message(socket, :edit, chat_message_params) do
    case MessageTree.update_chat_message(socket.assigns.chat_message, chat_message_params) do
      {:ok, chat_message} ->
        notify_parent({:saved, chat_message})

        {:noreply,
         socket
         |> put_flash(:info, "Chat message updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_chat_message(socket, :new, chat_message_params) do
    Logger.debug "save_chat_message assigns: #{inspect(socket.assigns)}"
    case MessageTree.create_chat_message(chat_message_params) do
      {:ok, chat_message} ->
        notify_parent({:saved, chat_message})

        {:noreply,
         socket
         |> put_flash(:info, "Chat message created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
