class DigitalObject < Sequel::Model(:digital_object)
  include ASModel
  corresponds_to JSONModel(:digital_object)

  include Subjects
  include Extents
  include Dates
  include ExternalDocuments
  include Agents
  include Trees
  include DigitalObjectTrees
  include Notes
  include RightsStatements
  include ExternalIDs
  include FileVersions
  include CollectionManagements
  include UserDefineds

  agent_relator_enum("linked_agent_archival_record_relators")

  tree_of(:digital_object, :digital_object_component)
  set_model_scope :repository

  define_relationship(:name => :instance_do_link,
                      :contains_references_to_types => proc {[Instance]})


  def self.sequel_to_jsonmodel(obj, opts = {})
    json = super

    json["linked_instances"] = []

    obj.related_records(:instance_do_link).each do |link|
      uri = link.resource.uri if link.resource
      uri = link.archival_object.uri if link.archival_object
      uri = link.accession.uri if link.accession

      if uri.nil?
        raise "Digital Object Instance not linked to either a resource, archival object or accession"
      end

        json["linked_instances"].push({
            "ref" => uri
        })
    end

    json
  end


  repo_unique_constraint(:digital_object_id,
                         :message => "Must be unique",
                         :json_property => :digital_object_id)

end
