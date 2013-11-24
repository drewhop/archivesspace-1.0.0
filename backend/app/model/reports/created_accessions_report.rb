class CreatedAccessionsReport < AbstractReport
  register_report({
                    :uri_suffix => "created_accessions",
                    :description => "Report on accessions created within a date range",
                    :params => [["from", Date, "The start of report range"],
                                ["to", Date, "The start of report range"]]
                  })

  def initialize(params)
    super
    @from = DateTime.parse(params[:from].strftime("%Y-%m-%d"))
    @to = DateTime.parse(params[:to].strftime("%Y-%m-%d"))
  end

  def title
    "Fort Worth Aviation Archive Accessions"
#    "Accessions created between #{@from.strftime("%Y-%m-%d")} and #{@to.strftime("%Y-%m-%d")}"
  end

  def headers
    ['id', 'accession_date', 'identifier', 'title', 'description', 'create_date', 'create_time']
  end

  def processor
    {
      'accession_date' => proc {|record| record[:accession_date]},
      'identifier' => proc {|record| ASUtils.json_parse(record[:identifier] || "[]").compact.join("-")},
      'description' => proc {|record| record[:content_description]},
      'create_date' => proc {|record| record[:create_time].strftime("%Y-%m-%d")},
      'create_time' => proc {|record| record[:create_time].strftime("%H:%M:%S")}
    }
  end

  def query(db)
    db[:accession].where(:create_time => (@from..@to)).order(Sequel.asc(:create_time))
  end

end
