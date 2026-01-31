defmodule RepositWeb.UserSessionHTML do
  use RepositWeb, :html

  embed_templates("user_session_html/*")

  defp local_mail_adapter? do
    Application.get_env(:reposit, Reposit.Mailer)[:adapter] == Swoosh.Adapters.Local
  end
end
