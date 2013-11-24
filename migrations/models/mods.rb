ASpaceExport::model :mods do
  
  include JSONModel

  attr_accessor :title
  attr_accessor :language_term
  attr_accessor :extents
  attr_accessor :notes
  attr_accessor :subjects
  attr_accessor :names
  attr_accessor :type_of_resource
  attr_accessor :parts
  
  
  @archival_object_map = {
    :title => :title=,
    :language => :language_term=,
    :extents => :handle_extent,
    :subjects => :handle_subjects,
    :linked_agents => :handle_agents

  }
  
  @digital_object_map = {
    :notes => :handle_notes
  }
  
  
  @name_type_map = {
    'agent_person' => 'personal',
    'agent_family' => 'family',
    'agent_corporate' => 'corporate',
    'agent_software' => nil
  }
  
  @name_part_type_map = {
    'primary_name' => 'family',
    'title' => 'termsOfAddress',
    'rest_of_name' => 'given',
    'family_name' => 'family',
    'prefix' => 'termsOfAddress'
  }
    

  def initialize
    @extents = []
    @notes = []
    @subjects = []
    @names = []
    @parts = []
  end
    

  # meaning, 'archival object' in the abstract
  def self.from_archival_object(obj)
    
    mods = self.new
    
    mods.apply_map(obj, @archival_object_map)
         
    mods
  end
    
  
  def self.from_digital_object(obj)
    
    mods = self.from_archival_object(obj)
    
    mods.type_of_resource = obj.digital_object_type
    
    mods.apply_map(obj, @digital_object_map)
    
    obj.tree['_resolved']['children'].each do |child|
      mods.parts << {'id' => "component-#{child['id']}", 'title' => child['title']}
    end
  
    mods
  end
  
  def self.name_type_map
    @name_type_map
  end
  
  def self.name_part_type_map
    @name_part_type_map
  end
  
  
  def handle_notes(notes)
    notes.each do |note|
     self.notes << note
    end 
  end
  
  def handle_extent(extents)
    extents.each do |ext|
      e = ext['number']
      e << " (#{ext['portion']})" if ext['portion']
      e << " #{ext['extent_type']}"

      self.extents << e
    end
  end
  
  def handle_subjects(subjects)
    subjects.map {|s| s['_resolved'] }.each do |subject|
      self.subjects << {'terms' => subject['terms'].map {|t| t['term']}}
    end
  end
  
  def handle_agents(linked_agents)
    linked_agents.each do |link|
      agent = link['_resolved']
      role = link['role']
      name_type = self.class.name_type_map[agent['jsonmodel_type']]
      # shift in granularity - role repeats for each name
      agent['names'].each do |name|
        self.names << {'type' => name_type, 
                       'role' => role, 
                       'parts' => name_parts(name, agent['jsonmodel_type']),
                       'displayForm' => name['sort_name']
                       }
      end
    end
  end
  
  def name_parts(name, type)
    fields = case type
              when 'agent_person'
                ["primary_name", "title", "prefix", "rest_of_name", "suffix", "fuller_form", "number"]
              when 'agent_family'
                ["family_name", "prefix"]
              when 'agent_software'
                ["software_name", "version", "manufacturer"]
              when 'agent_corporate_entity'
                ["primary_name", "subordinate_name_1", "subordinate_name_2", "number"]
              end
    parts = []
    fields.each do |field|
      part = {}
      part['type'] = self.class.name_part_type_map[field] 
      part.delete('type') if part['type'].nil?
      part['content'] = name[field] unless name[field].nil?
      parts << part unless part.empty?
    end
    parts    
  end
end
