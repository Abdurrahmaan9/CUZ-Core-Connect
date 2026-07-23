defmodule CuzCoreConnect.Accounts do
  @moduledoc """
  The Account context.
  """

  import Ecto.Query, warn: false
  alias CuzCoreConnect.Repo

  alias CuzCoreConnect.Accounts.{User, UserToken, UserNotifier, StudentEmail}

  ## Database getters

  @doc """
  Gets a user by email.

  ## Examples

      iex> get_user_by_email("foo@example.com")
      %User{}

      iex> get_user_by_email("unknown@example.com")
      nil

  """
  def get_user_by_email(email) when is_binary(email) do
    Repo.get_by(User, email: email)
  end

  @doc """
  Gets a student user by institutional student number.
  """
  def get_user_by_student_number(student_number) when is_binary(student_number) do
    number = StudentEmail.normalize_student_number(student_number)

    if number == "" do
      nil
    else
      Repo.get_by(User, student_number: number)
    end
  end

  def get_user_by_student_number(_), do: nil

  @doc """
  Gets a user by email and password.

  ## Examples

      iex> get_user_by_email_and_password("foo@example.com", "correct_password")
      %User{}

      iex> get_user_by_email_and_password("foo@example.com", "invalid_password")
      nil

  """
  def get_user_by_email_and_password(email, password)
      when is_binary(email) and is_binary(password) do
    user = Repo.get_by(User, email: email)

    # Deactivated users keep their historical data but must not be able to
    # authenticate. Check is_active here so every password-login path is
    # covered without relying on the UI alone.
    if user && user.is_active && User.valid_password?(user, password) do
      user
    end
  end

  @doc """
  Gets recent users ordered by creation date.

  ## Examples

      iex> list_recent_users()
      [%User{}, ...]

  """
  def list_recent_users(limit \\ 5) do
    from(u in User, order_by: [desc: u.inserted_at], limit: ^limit)
    |> Repo.all()
  end

  @doc """
  Gets all users ordered by creation date.

  ## Examples

      iex> list_all_users()
      [%User{}, ...]

  """
  def list_all_users do
    from(u in User, order_by: [desc: u.inserted_at])
    |> Repo.all()
  end

  def count_users do
    from(u in User, where: is_nil(u.deleted_at), select: count(u.id))
    |> Repo.one()
  end

  @doc """
  Gets internal users ordered by creation date.

  ## Examples

      iex> list_all_internal_users()
      [%User{}, ...]

  """
  def list_all_internal_users do
    User
    |> where([f], is_nil(f.deleted_at))
    |> where([f], f.user_role != "student")
    |> order_by(desc: :inserted_at)
    |> Repo.all()
  end

  @doc """
  Gets external users ordered by creation date.

  ## Examples

      iex> list_all_external_users()
      [%User{}, ...]

  """
  def list_all_external_users do
    User
    |> where([f], is_nil(f.deleted_at))
    |> where([f], f.user_role == "student")
    |> order_by(desc: :inserted_at)
    |> Repo.all()
  end

  @doc """
  Active users whose role is in the given list.
  """
  def list_active_users_by_roles(roles) when is_list(roles) do
    from(u in User,
      where: is_nil(u.deleted_at) and u.is_active == true and u.user_role in ^roles,
      order_by: [asc: u.email]
    )
    |> Repo.all()
  end

  def list_active_users_by_roles(role) when is_binary(role), do: list_active_users_by_roles([role])

  @doc """
  Gets a single user.

  Raises `Ecto.NoResultsError` if the User does not exist.

  ## Examples

      iex> get_user!(123)
      %User{}

      iex> get_user!(456)
      ** (Ecto.NoResultsError)

  """
  def get_user!(id), do: Repo.get!(User, id)

  @doc """
  Updates an existing user from the admin panel (role, active flag, profile fields).
  Deactivating (`is_active: false`) preserves the row and historical data but
  blocks further logins via `get_user_by_email_and_password/2`.
  """
  def update_user(%User{} = user, attrs) do
    attrs =
      attrs
      |> Map.new(fn {k, v} -> {to_string(k), v} end)
      |> then(fn params ->
        # Unchecked HTML checkboxes omit the field entirely.
        Map.put_new(params, "is_active", false)
      end)
      |> then(fn params ->
        case params["is_active"] do
          v when v in [true, "true", "on", "1"] -> Map.put(params, "is_active", true)
          _ -> Map.put(params, "is_active", false)
        end
      end)

    user
    |> User.admin_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Soft-deactivates a user without deleting historical registrations/approvals.
  """
  def deactivate_user(%User{} = user) do
    update_user(user, %{"is_active" => false, "status" => "INACTIVE"})
  end

  ## User registration

  @doc """
  Registers a user.

  Options:

    * `:notify` - when `true`, emails the generated (or provided) password to
      the user via Swoosh. In development that appears at `/dev/mailbox`.

  ## Examples

      iex> register_user(%{field: value})
      {:ok, %User{}}

      iex> register_user(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def register_user(attrs, opts \\ []) do
    # Normalize keys to strings first so we never end up casting a changeset
    # with a map that mixes atom and string keys (Ecto.Changeset.cast/3 raises
    # an Ecto.CastError in that case).
    attrs = for {key, val} <- attrs, into: %{}, do: {to_string(key), val}
    password = Map.get(attrs, "password") || User.generate_random_password()

    %User{}
    |> User.registration_changeset(Map.put(attrs, "password", password))
    |> Repo.insert()
    |> case do
      {:ok, user} ->
        # Inherit all pages for their role
        CuzCoreConnect.Pages.assign_default_pages_for_user(user)

        if Keyword.get(opts, :notify, false) do
          _ = deliver_account_credentials(user, password)
        end

        {:ok, user}

      {:error, r} ->
        {:error, r}
    end
  end

  @doc """
  Registers a student portal account from `/users/register`.

  Generates a password, confirms the account, emails login credentials, and
  always assigns the `student` role.
  """
  def register_student(attrs, opts \\ []) do
    attrs = normalize_attrs(attrs)
    password = Map.get(attrs, "password") || User.generate_random_password()

    attrs =
      attrs
      |> Map.put("password", password)
      |> Map.put("user_role", "student")
      |> put_student_username()

    %User{}
    |> User.student_registration_changeset(attrs)
    |> Repo.insert()
    |> case do
      {:ok, user} ->
        {:ok, user} =
          user
          |> User.confirm_changeset()
          |> Repo.update()

        CuzCoreConnect.Pages.assign_default_pages_for_user(user)

        if Keyword.get(opts, :notify, true) do
          _ = deliver_account_credentials(user, password)
        end

        {:ok, user}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  @doc """
  Ensures a student account exists for the email used on a course registration.

  Returns `{:ok, user, :existing | :created}`. When created, login credentials
  are emailed to the student.
  """
  def ensure_student_account(attrs, opts \\ []) when is_map(attrs) do
    attrs = normalize_attrs(attrs)

    attrs =
      cond do
        blank_to_nil(Map.get(attrs, "student_number")) ->
          attrs

        blank_to_nil(Map.get(attrs, "student_id")) ->
          Map.put(attrs, "student_number", Map.get(attrs, "student_id"))

        true ->
          attrs
      end

    email =
      attrs
      |> Map.get("email")
      |> Kernel.||(Map.get(attrs, "student_email"))
      |> to_string()
      |> String.trim()
      |> String.downcase()

    student_number = StudentEmail.normalize_student_number(Map.get(attrs, "student_number"))

    cond do
      email == "" ->
        {:error, :missing_email}

      true ->
        case get_user_by_email(email) do
          %User{} = user ->
            {:ok, user, :existing}

          nil ->
            case student_number != "" && get_user_by_student_number(student_number) do
              %User{} = user ->
                {:ok, user, :existing}

              _ ->
                {first_name, middle_name, last_name} = split_student_names(attrs)

                case register_student(
                       %{
                         "email" => email,
                         "student_number" => student_number,
                         "first_name" => first_name,
                         "last_name" => last_name,
                         "middle_name" => middle_name
                       },
                       notify: Keyword.get(opts, :notify, true)
                     ) do
                  {:ok, user} ->
                    {:ok, user, :created}

                  {:error, changeset} ->
                    {:error, changeset}
                end
            end
        end
    end
  end

  defp normalize_attrs(attrs) do
    for {key, val} <- attrs, into: %{}, do: {to_string(key), val}
  end

  defp put_student_username(attrs) do
    existing = Map.get(attrs, "username")

    if is_binary(existing) and String.trim(existing) != "" do
      attrs
    else
      full_name =
        [Map.get(attrs, "first_name"), Map.get(attrs, "middle_name"), Map.get(attrs, "last_name")]
        |> Enum.reject(&(is_nil(&1) or String.trim(to_string(&1)) == ""))
        |> Enum.map(&String.trim(to_string(&1)))
        |> Enum.join(" ")

      student_number = StudentEmail.normalize_student_number(Map.get(attrs, "student_number"))

      username =
        cond do
          full_name != "" and student_number != "" -> "#{full_name} (#{student_number})"
          full_name != "" -> full_name
          student_number != "" -> student_number
          true -> Map.get(attrs, "email")
        end

      Map.put(attrs, "username", username)
    end
  end

  defp split_student_names(attrs) do
    first = blank_to_nil(Map.get(attrs, "first_name"))
    middle = blank_to_nil(Map.get(attrs, "middle_name"))
    last = blank_to_nil(Map.get(attrs, "last_name"))

    if first && last do
      {first, middle, last}
    else
      names =
        attrs
        |> Map.get("student_names")
        |> to_string()
        |> String.trim()
        |> String.split(~r/\s+/, trim: true)

      case names do
        [f, l] -> {f, nil, l}
        [f, m, l] -> {f, m, l}
        [f, m | rest] -> {f, m, Enum.join(rest, " ")}
        [f] -> {f, nil, f}
        _ -> {"Student", nil, Map.get(attrs, "student_number") || "portal"}
      end
    end
  end

  defp blank_to_nil(nil), do: nil

  defp blank_to_nil(value) do
    case String.trim(to_string(value)) do
      "" -> nil
      trimmed -> trimmed
    end
  end

  @doc """
  Emails temporary account credentials to a newly created user.
  """
  def deliver_account_credentials(%User{} = user, password) when is_binary(password) do
    login_url = CuzCoreConnectWeb.Endpoint.url() <> "/users/log-in"
    UserNotifier.deliver_account_credentials(user, password, login_url)
  end

  ## Settings

  @doc """
  Checks whether the user is in sudo mode.

  The user is in sudo mode when the last authentication was done no further
  than 20 minutes ago. The limit can be given as second argument in minutes.
  """
  def sudo_mode?(user, minutes \\ -20)

  def sudo_mode?(%User{authenticated_at: ts}, minutes) when is_struct(ts, DateTime) do
    DateTime.after?(ts, DateTime.utc_now() |> DateTime.add(minutes, :minute))
  end

  def sudo_mode?(_user, _minutes), do: false

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the user email.

  See `CuzCoreConnect.Accounts.User.email_changeset/3` for a list of supported options.

  ## Examples

      iex> change_user_email(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user_email(user, attrs \\ %{}, opts \\ []) do
    User.email_changeset(user, attrs, opts)
  end

  @doc """
  Updates the user email using the given token.

  If the token matches, the user email is updated and the token is deleted.
  """
  def update_user_email(user, token) do
    context = "change:#{user.email}"

    Repo.transact(fn ->
      with {:ok, query} <- UserToken.verify_change_email_token_query(token, context),
           %UserToken{sent_to: email} <- Repo.one(query),
           {:ok, user} <- Repo.update(User.email_changeset(user, %{email: email})),
           {_count, _result} <-
             Repo.delete_all(from(UserToken, where: [user_id: ^user.id, context: ^context])) do
        {:ok, user}
      else
        _ -> {:error, :transaction_aborted}
      end
    end)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the user password.

  See `CuzCoreConnect.Accounts.User.password_changeset/3` for a list of supported options.

  ## Examples

      iex> change_user_password(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user_password(user, attrs \\ %{}, opts \\ []) do
    User.password_changeset(user, attrs, opts)
  end

  @doc """
  Updates the user password.

  Returns a tuple with the updated user, as well as a list of expired tokens.

  ## Examples

      iex> update_user_password(user, %{password: ...})
      {:ok, {%User{}, [...]}}

      iex> update_user_password(user, %{password: "too short"})
      {:error, %Ecto.Changeset{}}

  """
  def update_user_password(user, attrs) do
    user
    |> User.password_changeset(attrs)
    |> update_user_and_delete_all_tokens()
  end

  ## Session

  @doc """
  Generates a session token.
  """
  def generate_user_session_token(user) do
    {token, user_token} = UserToken.build_session_token(user)
    Repo.insert!(user_token)
    token
  end

  @doc """
  Gets the user with the given signed token.

  If the token is valid `{user, token_inserted_at}` is returned, otherwise `nil` is returned.
  """
  def get_user_by_session_token(token) do
    {:ok, query} = UserToken.verify_session_token_query(token)

    case Repo.one(query) do
      {%User{is_active: false}, _token_inserted_at} ->
        nil

      {%User{} = user, token_inserted_at} ->
        {user, token_inserted_at}

      other ->
        other
    end
  end

  @doc """
  Gets the user with the given magic link token.
  """
  def get_user_by_magic_link_token(token) do
    with {:ok, query} <- UserToken.verify_magic_link_token_query(token),
         {user, _token} <- Repo.one(query) do
      user
    else
      _ -> nil
    end
  end

  @doc """
  Logs the user in by magic link.

  There are three cases to consider:

  1. The user has already confirmed their email. They are logged in
     and the magic link is expired.

  2. The user has not confirmed their email and no password is set.
     In this case, the user gets confirmed, logged in, and all tokens -
     including session ones - are expired. In theory, no other tokens
     exist but we delete all of them for best security practices.

  3. The user has not confirmed their email but a password is set.
     This cannot happen in the default implementation but may be the
     source of security pitfalls. See the "Mixing magic link and password registration" section of
     `mix help phx.gen.auth`.
  """
  def login_user_by_magic_link(token) do
    {:ok, query} = UserToken.verify_magic_link_token_query(token)

    case Repo.one(query) do
      # NOTE: Unlike the default `phx.gen.auth` implementation, every account in this
      # app is created with a password (auto-generated when one isn't supplied, see
      # `register_user/1`), so we intentionally do NOT raise when an unconfirmed user
      # has a password set - that is the normal case here, not a sign of misuse.
      {%User{is_active: false}, _token} ->
        {:error, :inactive}

      {%User{confirmed_at: nil} = user, _token} ->
        user
        |> User.confirm_changeset()
        |> update_user_and_delete_all_tokens()

      {user, token} ->
        Repo.delete!(token)
        {:ok, {user, []}}

      nil ->
        {:error, :not_found}
    end
  end

  @doc ~S"""
  Delivers the update email instructions to the given user.

  ## Examples

      iex> deliver_user_update_email_instructions(user, current_email, &url(~p"/users/settings/confirm-email/#{&1}"))
      {:ok, %{to: ..., body: ...}}

  """
  def deliver_user_update_email_instructions(%User{} = user, current_email, update_email_url_fun)
      when is_function(update_email_url_fun, 1) do
    {encoded_token, user_token} = UserToken.build_email_token(user, "change:#{current_email}")

    Repo.insert!(user_token)
    UserNotifier.deliver_update_email_instructions(user, update_email_url_fun.(encoded_token))
  end

  @doc """
  Delivers the magic link login instructions to the given user.
  """
  def deliver_login_instructions(%User{} = user, magic_link_url_fun)
      when is_function(magic_link_url_fun, 1) do
    {encoded_token, user_token} = UserToken.build_email_token(user, "login")
    Repo.insert!(user_token)
    UserNotifier.deliver_login_instructions(user, magic_link_url_fun.(encoded_token))
  end

  @doc """
  Deletes the signed token with the given context.
  """
  def delete_user_session_token(token) do
    Repo.delete_all(from(UserToken, where: [token: ^token, context: "session"]))
    :ok
  end

  ## Token helper

  defp update_user_and_delete_all_tokens(changeset) do
    Repo.transact(fn ->
      with {:ok, user} <- Repo.update(changeset) do
        tokens_to_expire = Repo.all_by(UserToken, user_id: user.id)

        Repo.delete_all(from(t in UserToken, where: t.id in ^Enum.map(tokens_to_expire, & &1.id)))

        {:ok, {user, tokens_to_expire}}
      end
    end)
  end
end
