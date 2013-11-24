class NameFamily < Sequel::Model(:name_family)
  include ASModel
  corresponds_to JSONModel(:name_family)

  include AgentNames
  include AutoGenerator

  auto_generate :property => :sort_name,
                :generator => proc  { |json|
                  result = ""

                  result << json["family_name"] if json["family_name"]
                  result << ", #{json["prefix"]}" if json["prefix"]
                  result << ", #{json["dates"]}" if json["dates"]
                  result << " (#{json["qualifier"]})" if json["qualifier"]

                  result.length > 255 ? result[0..254] : result
                },
                :only_if => proc { |json| json["sort_name_auto_generate"] }
end
