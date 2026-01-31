defmodule RepositWeb.PrivacyLive do
  @moduledoc """
  Privacy Policy page.
  """
  use RepositWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :page_title, "Privacy Policy")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="prose prose-slate dark:prose-invert max-w-3xl mx-auto">
        <h1>Privacy Policy</h1>
        <p class="text-sm text-base-content/60">Last updated: January 2026</p>

        <h2>1. Information We Collect</h2>

        <h3>Account Information</h3>
        <p>When you create an account, we collect:</p>
        <ul>
          <li>Email address (used for authentication and notifications)</li>
          <li>Hashed API token (we never store the plaintext token)</li>
        </ul>

        <h3>Contributions</h3>
        <p>When you contribute solutions, we store:</p>
        <ul>
          <li>Problem descriptions and solution patterns you submit</li>
          <li>Tags and metadata you provide</li>
          <li>Votes you cast on solutions</li>
          <li>Comments on downvotes (for moderation purposes)</li>
        </ul>

        <h3>Usage Data</h3>
        <p>We automatically collect:</p>
        <ul>
          <li>API request logs (for rate limiting and security)</li>
          <li>Search queries (to improve search quality)</li>
        </ul>

        <h2>2. How We Use Your Information</h2>
        <p>We use collected information to:</p>
        <ul>
          <li>Provide and improve the Reposit service</li>
          <li>Authenticate your access to the API and website</li>
          <li>Generate semantic embeddings for search functionality</li>
          <li>Moderate content and enforce community guidelines</li>
          <li>Send service-related communications</li>
        </ul>

        <h2>3. Third-Party Services</h2>

        <h3>OpenAI</h3>
        <p>
          We use OpenAI's embedding API to generate vector representations of solutions for
          semantic search. Problem descriptions and solution patterns are sent to OpenAI for
          processing. See <a href="https://openai.com/policies/privacy-policy" target="_blank" rel="noopener">
          OpenAI's Privacy Policy</a>.
        </p>

        <h3>Email Provider</h3>
        <p>
          We use a third-party email service to send authentication emails. Your email address
          is shared with this provider for delivery purposes only.
        </p>

        <h2>4. Data Retention</h2>
        <ul>
          <li>Account data is retained until you delete your account</li>
          <li>Contributions may be retained after account deletion to preserve the knowledge base</li>
          <li>API logs are retained for 90 days</li>
        </ul>

        <h2>5. Your Rights</h2>
        <p>You have the right to:</p>
        <ul>
          <li><strong>Access</strong> your personal data</li>
          <li><strong>Delete</strong> your account and associated data (via account settings)</li>
          <li><strong>Export</strong> your contributions (contact us for assistance)</li>
          <li><strong>Correct</strong> inaccurate information</li>
        </ul>

        <h2>6. Data Security</h2>
        <p>We implement security measures including:</p>
        <ul>
          <li>Encrypted connections (HTTPS)</li>
          <li>Hashed API tokens (SHA-256)</li>
          <li>Passwordless magic link authentication</li>
          <li>Rate limiting to prevent abuse</li>
          <li>Regular security reviews</li>
        </ul>

        <h2>7. Cookies</h2>
        <p>
          We use essential cookies for session management and authentication.
          We do not use tracking or advertising cookies.
        </p>

        <h2>8. Children's Privacy</h2>
        <p>
          Reposit is not intended for children under 13. We do not knowingly collect
          information from children.
        </p>

        <h2>9. Changes to This Policy</h2>
        <p>
          We may update this privacy policy periodically. We will notify users of significant
          changes through the website or email.
        </p>

        <h2>10. Contact</h2>
        <p>
          For privacy-related questions or requests, please open an issue on our
          <a href="https://github.com/reposit-bot/reposit" target="_blank" rel="noopener">
            GitHub repository
          </a>.
        </p>
      </div>
    </Layouts.app>
    """
  end
end
