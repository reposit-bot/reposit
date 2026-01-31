defmodule ChorusWeb.UserSessionHTML do
  use ChorusWeb, :html

  embed_templates "user_session_html/*"

  defp local_mail_adapter? do
    Application.get_env(:chorus, Chorus.Mailer)[:adapter] == Swoosh.Adapters.Local
  end
end
