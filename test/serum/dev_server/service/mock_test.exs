defmodule Serum.DevServer.Service.MockTest do
  use Serum.Case, async: true
  alias Serum.DevServer.Service.Mock, as: MockService

  setup_all do
    child = %{
      id: MockService,
      start: {MockService, :start_link, ["/tmp/src/", "/tmp/site/"]}
    }

    start_supervised!(child)

    :ok
  end

  test "rebuild/0" do
    assert :ok === MockService.rebuild()
  end

  test "source_dir/0" do
    assert "/tmp/src/" === MockService.source_dir()
  end

  test "site_dir/0" do
    assert "/tmp/site/" === MockService.site_dir()
  end

  test "port/0" do
    assert 8080 === MockService.port()
  end

  test "dirty?/0" do
    assert false === MockService.dirty?()
  end

  test "subscribe/0" do
    assert :ok === MockService.subscribe()
  end
end
