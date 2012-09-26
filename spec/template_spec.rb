require File.dirname(__FILE__) + '/spec_helper.rb'

describe RightSignature::Template do 
  describe "list" do
    it "should GET /api/templates.xml" do
      RightSignature::Connection.should_receive(:get).with('/api/templates.xml', {})
      RightSignature::Template.list
    end

    it "should pass search options to /api/templates.xml" do
      RightSignature::Connection.should_receive(:get).with('/api/templates.xml', {:search => "search", :page => 2})
      RightSignature::Template.list(:search => "search", :page => 2)
    end
    
    it "should convert tags array of mixed strings and hashes into into normalized Tag string" do
      RightSignature::Connection.should_receive(:get).with('/api/templates.xml', {:tags => "hello,abc:def,there"})
      RightSignature::Template.list(:tags => ["hello", {"abc" => "def"}, "there"])
    end

    it "should keep tags as string if :tags is a string" do
      RightSignature::Connection.should_receive(:get).with('/api/templates.xml', {:tags => "voice,no:way,microphone"})
      RightSignature::Template.list(:tags => "voice,no:way,microphone")
    end
  end
  
  describe "details" do
    it "should GET /api/templates/MYGUID.xml" do
      RightSignature::Connection.should_receive(:get).with('/api/templates/MYGUID.xml', {})
      RightSignature::Template.details('MYGUID')
    end
  end

  describe "prepackage" do
    it "should POST /api/templates/MYGUID/prepackage.xml" do
      RightSignature::Connection.should_receive(:post).with('/api/templates/MYGUID/prepackage.xml', {})
      RightSignature::Template.prepackage('MYGUID')
    end
  end

  
  describe "prepackage_and_send" do
    it "should POST /api/templates/GUID123/prepackage.xml and POST /api/templates.xml using guid, and subject from prepackage response" do
      RightSignature::Connection.should_receive(:post).with('/api/templates/GUID123/prepackage.xml', 
        {}
      ).and_return({"template" => {
        "guid" => "a_123985_1z9v8pd654",
        "subject" => "subject template",
        "message" => "Default message here"
      }})
      RightSignature::Connection.should_receive(:post).with('/api/templates.xml', {:template => {
          :guid => "a_123985_1z9v8pd654", 
          :action => "send", 
          :subject => "sign me", 
          :roles => []
        }})
      RightSignature::Template.prepackage_and_send("GUID123", "sign me", [])
    end
  end

  describe "prefill/send_template" do
    it "should POST /api/templates.xml with action of 'prefill', MYGUID guid, roles, and \"sign me\" subject in template hash" do
      RightSignature::Connection.should_receive(:post).with('/api/templates.xml', {:template => {:guid => "MYGUID", :action => "prefill", :subject => "sign me", :roles => []}})
      RightSignature::Template.prefill("MYGUID", "sign me", [])
    end
    
    it "should add \"@role_name\"=>'Employee' key to roles in xml hash" do
      RightSignature::Connection.should_receive(:post).with('/api/templates.xml', {
        :template => {
          :guid => "MYGUID", 
          :action => "prefill",
          :subject => "sign me", 
          :roles => [
            {:role => {
              :name => "John Employee", 
              :email => "john@employee.com", 
              "@role_name" => "Employee"
            }}
          ]
        }
      })
      RightSignature::Template.prefill("MYGUID", "sign me", [{"Employee" => {:name => "John Employee", :email => "john@employee.com"}}])
    end

    describe "optional options" do
      it "should add \"@merge_field_name\"=>'Tax_id' key to merge_fields in xml hash" do
        RightSignature::Connection.should_receive(:post).with('/api/templates.xml', {
          :template => {
            :guid => "MYGUID", 
            :action => "prefill",
            :subject => "sign me", 
            :roles => [
            ],
            :merge_fields => [{:merge_field => {:value => "123456", "@merge_field_name" => "Tax_id"}}]
          }
        })
        RightSignature::Template.prefill("MYGUID", "sign me", [], {:merge_fields => [{"Tax_id" => "123456"}]})
      end

      it "should add \"tag\" key to tags in xml hash" do
        RightSignature::Connection.should_receive(:post).with('/api/templates.xml', {
          :template => {
            :guid => "MYGUID", 
            :action => "prefill",
            :subject => "sign me", 
            :roles => [],
            :tags => [{:tag => {:name => "I_Key", :value => "I_Value"}}, {:tag => {:name => "Alone"}}]
          }
        })
        RightSignature::Template.prefill("MYGUID", "sign me", [], {:tags => [{"I_Key" => "I_Value"}, "Alone"]})
      end

      it "should include options :expires_in, :description, and :callback_url" do
        RightSignature::Connection.should_receive(:post).with('/api/templates.xml', {
          :template => {
            :guid => "MYGUID", 
            :action => "prefill",
            :subject => "sign me", 
            :roles => [],
            :expires_in => 15, 
            :description => "Hey, I'm a description", 
            :callback_url => 'http://example.com/callie'
          }
        })
        RightSignature::Template.prefill("MYGUID", "sign me", [], {:expires_in => 15, :description => "Hey, I'm a description", :callback_url => "http://example.com/callie"})
      end
    end

    it "should POST /api/templates.xml with action of 'send', MYGUID guid, roles, and \"sign me\" subject in template hash" do
      RightSignature::Connection.should_receive(:post).with('/api/templates.xml', {:template => {:guid => "MYGUID", :action => "send", :subject => "sign me", :roles => []}})
      RightSignature::Template.send_template("MYGUID", "sign me", [])
    end
  end
  
  describe "generate_build_url" do
    it "should POST /api/templates/generate_build_token.xml" do
      RightSignature::Connection.should_receive(:post).with("/api/templates/generate_build_token.xml", {:template => {}}).and_return({"token"=>{"redirect_token" => "REDIRECT_TOKEN"}})
      RightSignature::Template.generate_build_url
    end

    it "should return https://rightsignature.com/builder/new?rt=REDIRECT_TOKEN" do
      RightSignature::Connection.should_receive(:post).with("/api/templates/generate_build_token.xml", {:template => {}}).and_return({"token"=>{"redirect_token" => "REDIRECT_TOKEN"}})
      RightSignature::Template.generate_build_url.should == "#{RightSignature::Connection.site}/builder/new?rt=REDIRECT_TOKEN"
    end

    describe "options" do
      it "should include normalized :acceptable_merge_field_names in params" do
        RightSignature::Connection.should_receive(:post).with("/api/templates/generate_build_token.xml", {:template => 
          {:acceptable_merge_field_names => 
            [
              {:name => "Site ID"}, 
              {:name => "Starting City"}
            ]}
        }).and_return({"token"=>{"redirect_token" => "REDIRECT_TOKEN"}})
        RightSignature::Template.generate_build_url(:acceptable_merge_field_names => ["Site ID", "Starting City"])
      end

      it "should include normalized :acceptabled_role_names, in params" do
        RightSignature::Connection.should_receive(:post).with("/api/templates/generate_build_token.xml", {:template => 
          {:acceptabled_role_names => 
            [
              {:name => "Http Monster"}, 
              {:name => "Party Monster"}
            ]}
        }).and_return({"token"=>{"redirect_token" => "REDIRECT_TOKEN"}})
        RightSignature::Template.generate_build_url(:acceptabled_role_names => ["Http Monster", "Party Monster"])
      end

      it "should include normalized :tags in params" do
        RightSignature::Connection.should_receive(:post).with("/api/templates/generate_build_token.xml", {:template => 
          {:tags => 
            [
              {:tag => {:name => "Site"}}, 
              {:tag => {:name => "Starting City", :value => "NY"}}
            ]}
        }).and_return({"token"=>{"redirect_token" => "REDIRECT_TOKEN"}})
        RightSignature::Template.generate_build_url(:tags => ["Site", "Starting City" => "NY"])
      end
      
      it "should include :callback_location and :redirect_location in params" do
        RightSignature::Connection.should_receive(:post).with("/api/templates/generate_build_token.xml", {:template => {
          :callback_location => "http://example.com/done_signing", 
          :redirect_location => "http://example.com/come_back_here"
        }}).and_return({"token"=>{"redirect_token" => "REDIRECT_TOKEN"}})

        RightSignature::Template.generate_build_url(:callback_location => "http://example.com/done_signing", :redirect_location => "http://example.com/come_back_here")
      end
    end
  end
  
  describe "send_as_self_signers" do
    it "should prepackage template, send template with reciepents with noemail@rightsignature.com and return self-signer links" do
      RightSignature::Connection.should_receive(:post).with('/api/templates/TGUID/prepackage.xml', 
        {}
      ).and_return(  {"template"=>{
        "type"=>"Document",
        "guid"=>"a_123_456",
        "created_at"=>"2012-09-25T14:51:44-07:00",
        "filename"=>"assets-363-demo_document.pdf",
        "size"=>"14597",
        "content_type"=>"pdf",
        "page_count"=>"1",
        "subject"=>"subject template",
        "message"=>"Default message here",
        "tags"=>"template_id:31,user:1",
        "processing_state"=>"done-processing",
        "roles"=>
        {"role"=>
          [{"role"=>"Document Sender",
            "name"=>"Document Sender",
            "must_sign"=>"false",
            "document_role_id"=>"cc_A",
            "is_sender"=>"true"},
           {"role"=>"Leasee",
            "name"=>"Leasee",
            "must_sign"=>"true",
            "document_role_id"=>"signer_A",
            "is_sender"=>"false"},
           {"role"=>"Leaser",
            "name"=>"Leaser",
            "must_sign"=>"true",
            "document_role_id"=>"signer_B",
            "is_sender"=>"true"}]},
        "merge_fields"=>nil,
        "pages"=>
          {"page"=>
            {"page_number"=>"1",
             "original_template_guid"=>"GUID123",
             "original_template_filename"=>"demo_document.pdf"}
          },
        "thumbnail_url"=>
        "https%3A%2F%2Fs3.amazonaws.com%3A443%2Frightsignature.com%2Fassets%2F1464%2Fabcde_p1_t.png%3FSignature%3D1234AC",
        "redirect_token"=>
        "123456bcde"
      }})
      RightSignature::Connection.should_receive(:post).with('/api/templates.xml', {:template => {
          :guid => "a_123_456", 
          :action => "send", 
          :subject => "subject template",
          :roles => [
            {:role => {:name => "John Bellingham", :email => "noemail@rightsignature.com", "@role_name" => "Leasee"}},
            {:role => {:name => "Tim Else", :email => "noemail@rightsignature.com", "@role_name" => "Leaser"}}
          ]
        }}).and_return({"document"=> {
          "status"=>"sent", 
          "guid"=>"ABCDEFGH123"
        }})
      RightSignature::Connection.should_receive(:get).with("/api/documents/ABCDEFGH123/signer_links.xml", {}).and_return({"document" => {
        "signer_links" => [
          {"signer_link" => {"name" => "John Bellingham", "role" => "signer_A", "signer_token" => "slkfj2"}},
          {"signer_link" => {"name" => "Tim Else", "role" => "signer_B", "signer_token" => "asfd1"}}
        ]
      }})
      
      
      results = RightSignature::Template.send_as_embedded_signers("TGUID", [
        {"Leasee" => {:name => "John Bellingham"}}, 
        {"Leaser" => {:name => "Tim Else"}}
      ])
      results.size.should == 2
      results.include?({"name" => "John Bellingham", "url" => "#{RightSignature::Connection.site}/signatures/embedded?rt=slkfj2"})
      results.include?({"name" => "Tim Else", "url" => "#{RightSignature::Connection.site}/signatures/embedded?rt=asfd1"})
    end
    
    it "should pass in options"
  end
end