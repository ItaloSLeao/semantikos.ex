defmodule EventManager.Fixtures do
  @moduledoc """
  Fixtures for testing.
  """
  
  

  def unique_user_email, do: "user#{System.unique_integer()}@example.com"
  def valid_user_password, do: "Password@123"

  def valid_user_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      email: unique_user_email(),
      name: "Test User",
      password: valid_user_password(),
      role: :student
    })
  end

  def user_fixture(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> valid_user_attributes()
      |> EventManager.Core.register_user()

    user
  end

  def admin_fixture(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> Map.put(:role, :admin)
      |> valid_user_attributes()
      |> EventManager.Core.register_user()

    user
  end

  def speaker_fixture(attrs \\ %{}) do
    {:ok, user} =
