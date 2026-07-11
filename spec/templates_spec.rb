# frozen_string_literal: true

RSpec.describe CamelMailer::Templates do
  subject(:templates) { CamelMailer::Client.new(api_key: "cm_test_key").templates }

  it "lists templates" do
    stub_success(:get, "templates", data: { templates: [{ permalink: "welcome" }] })

    expect(templates.list[:templates].first[:permalink]).to eq("welcome")
  end

  it "creates a template" do
    params = { name: "Welcome", subject: "Hi {{ name }}", html_body: "<p>Hi {{ name }}</p>" }
    stub = stub_request(:post, "#{EnvelopeHelpers::BASE}/templates")
           .with(body: JSON.generate(params))
           .to_return(status: 201, body: success_json({ template: { permalink: "welcome" } }),
                      headers: json_headers)

    expect(templates.create(params)[:template][:permalink]).to eq("welcome")
    expect(stub).to have_been_requested
  end

  it "shows a template" do
    stub_success(:get, "templates/welcome", data: { template: { permalink: "welcome" } })

    expect(templates.get("welcome")[:template][:permalink]).to eq("welcome")
  end

  it "updates a template" do
    stub = stub_request(:patch, "#{EnvelopeHelpers::BASE}/templates/welcome")
           .with(body: JSON.generate({ subject: "Hello" }))
           .to_return(status: 200, body: success_json, headers: json_headers)

    templates.update("welcome", { subject: "Hello" })
    expect(stub).to have_been_requested
  end

  it "archives a template" do
    stub = stub_request(:post, "#{EnvelopeHelpers::BASE}/templates/welcome/archive")
           .to_return(status: 200, body: success_json, headers: json_headers)

    templates.archive("welcome")
    expect(stub).to have_been_requested
  end

  it "renders a template against a model" do
    stub = stub_request(:post, "#{EnvelopeHelpers::BASE}/templates/welcome/render")
           .with(body: JSON.generate({ template_model: { name: "Ada" } }))
           .to_return(status: 200, body: success_json({ subject: "Hi Ada" }), headers: json_headers)

    expect(templates.render("welcome", { name: "Ada" })[:subject]).to eq("Hi Ada")
    expect(stub).to have_been_requested
  end

  it "raises NotFoundError for unknown templates" do
    stub_error(:get, "templates/nope", code: "NotFound", message: "unknown template", status: 404)

    expect { templates.get("nope") }.to raise_error(CamelMailer::NotFoundError)
  end

  it "works at module level with global config" do
    configure_key!
    stub_success(:get, "templates", data: { templates: [] })

    expect(described_class.list).to eq({ templates: [] })
  end
end
