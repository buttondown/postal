# frozen_string_literal: true

require "rails_helper"

describe Postal::MessageParser do
  let(:server) { create(:server) }

  it "should not do anything when there are no tracking domains" do
    expect(server.track_domains.size).to eq 0
    message = create_plain_text_message(server, "Hello world!", "test@example.com")
    parser = Postal::MessageParser.new(message)
    expect(parser.actioned?).to be false
    expect(parser.tracked_links).to eq 0
    expect(parser.tracked_images).to eq 0
  end

  it "should replace links in messages" do
    message = create_plain_text_message(server, "Hello world! http://github.com/atech/postal", "test@example.com")
    create(:track_domain, server: server, domain: message.domain)
    parser = Postal::MessageParser.new(message)
    expect(parser.actioned?).to be true
    expect(parser.new_body).to match(/^Hello world! https:\/\/click\.#{message.domain.name}/)
    expect(parser.tracked_links).to eq 1
  end

  it "should not replace links in messages if the header is set to no" do
    message = create_plain_text_message(server, "Hello world! http://github.com/atech/postal", "test@example.com", { custom_headers: { "x-track-clicks" => "no" } })
    create(:track_domain, server: server, domain: message.domain)
    parser = Postal::MessageParser.new(message)
    expect(parser.actioned?).to be false
    expect(parser.new_body).to include("Hello world! http://github.com/atech/postal")
    expect(parser.tracked_links).to eq 0
  end

  it "should insert tracking pixels in messages" do
    message = create_html_message(server, "<p>Hello world! <a href='http://github.com/atech/postal'>Github</a></p>", "test@example.com")
    create(:track_domain, server: server, domain: message.domain)
    parser = Postal::MessageParser.new(message)
    expect(parser.actioned?).to be true
    expect(parser.new_body).to match(/<p class='ampimg' style='display:none;visibility:none;margin:0;padding:0;line-height:0;'><img src='https:\/\/click\.#{message.domain.name}/)
    expect(parser.tracked_images).to eq 1
  end

  it "should not insert tracking pixels in messages if the header is set to no" do
    message = create_html_message(server, "<p>Hello world! <a href='http://github.com/atech/postal'>Github</a></p>", "test@example.com", { custom_headers: { "x-track-opens" => "no" } })
    create(:track_domain, server: server, domain: message.domain)
    parser = Postal::MessageParser.new(message)
    expect(parser.actioned?).to be true
    expect(parser.new_body).to_not include("<p class='ampimg' style='display:none;visibility:none;margin:0;padding:0;line-height:0;'><img src='https:\/\/click\.#{message.domain.name}")
    expect(parser.tracked_images).to eq 0
  end
end
