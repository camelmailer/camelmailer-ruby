# frozen_string_literal: true

RSpec.describe CamelMailer::Layouts do
  subject(:layouts) { CamelMailer::Client.new(api_key: "cm_test_key").layouts }

  it "lists layouts" do
    stub_success(:get, "layouts", data: { layouts: [{ permalink: "default" }] })

    expect(layouts.list[:layouts].first[:permalink]).to eq("default")
  end

  it "creates a layout with the content placeholder" do
    params = { name: "Default", permalink: "default", html_wrapper: "<html>{{{ content }}}</html>" }
    stub = stub_request(:post, "#{EnvelopeHelpers::BASE}/layouts")
           .with(body: JSON.generate(params))
           .to_return(status: 201, body: success_json({ layout: params }), headers: json_headers)

    layouts.create(params)
    expect(stub).to have_been_requested
  end

  it "refuses a wrapper without the content placeholder" do
    stub_error(:post, "layouts", code: "ValidationError", message: "html_wrapper must contain {{{ content }}}")

    expect { layouts.create({ name: "Broken", html_wrapper: "<html></html>" }) }
      .to raise_error(CamelMailer::ValidationError)
  end

  it "gets, updates and deletes" do
    get_stub = stub_success(:get, "layouts/default", data: { layout: { permalink: "default" } })
    patch_stub = stub_success(:patch, "layouts/default", data: { layout: { name: "Renamed" } })
    delete_stub = stub_success(:delete, "layouts/default", data: { deleted: true })

    layouts.get("default")
    layouts.update("default", { name: "Renamed" })
    layouts.delete("default")

    expect(get_stub).to have_been_requested
    expect(patch_stub).to have_been_requested
    expect(delete_stub).to have_been_requested
  end

  it "uploads a logo as a data URL" do
    stub = stub_request(:post, "#{EnvelopeHelpers::BASE}/layouts/default/logo")
           .with(body: JSON.generate({ data_url: "data:image/png;base64,iVBORw0KGgo=" }))
           .to_return(status: 200, body: success_json({ logo_url: "https://app.camelmailer.com/l.png" }),
                      headers: json_headers)

    expect(layouts.upload_logo("default", "data:image/png;base64,iVBORw0KGgo=")[:logo_url])
      .to eq("https://app.camelmailer.com/l.png")
    expect(stub).to have_been_requested
  end
end
