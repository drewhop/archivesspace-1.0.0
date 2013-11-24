class ArchivesSpaceService < Sinatra::Base

  BASE_SEARCH_PARAMS =
    [["q", String, "A search query string",
      :optional => true],
     ["aq", JSONModel(:advanced_query), "A json string containing the advanced query",
      :optional => true],
     ["type",
      [String],
      "The record type to search (defaults to all types if not specified)",
      :optional => true],
     ["sort",
      String,
      "The attribute to sort and the direction e.g. &sort=title desc&...",
      :optional => true],
     ["facet",
      [String],
      "The list of the fields to produce facets for",
      :optional => true],
     ["filter_term", [String], "A json string containing the term/value pairs to be applied as filters.  Of the form: {\"fieldname\": \"fieldvalue\"}.",
      :optional => true],
     ["exclude",
      [String],
      "A list of document IDs that should be excluded from results",
      :optional => true]]


  Endpoint.get('/repositories/:repo_id/search')
    .description("Search this repository")
    .params(["repo_id", :repo_id],
            *BASE_SEARCH_PARAMS)
    .paginated(true)
    .permissions([:view_repository])
    .returns([200, ""]) \
  do
    json_response(Search.search(params, params[:repo_id]))
  end


  Endpoint.get('/search')
    .description("Search this archive")
    .params(*BASE_SEARCH_PARAMS)
    .permissions([:view_all_records])
    .paginated(true)
    .returns([200, ""]) \
  do
    json_response(Search.search(params, nil))
  end


  Endpoint.get('/search/repositories')
    .description("Search across repositories")
    .params(*BASE_SEARCH_PARAMS)
    .permissions([])
    .paginated(true)
    .returns([200, ""]) \
  do
    json_response(Search.search(params.merge(:type => ['repository']), nil))
  end


  Endpoint.get('/search/subjects')
    .description("Search across subjects")
    .params(*BASE_SEARCH_PARAMS)
    .permissions([])
    .paginated(true)
    .returns([200, ""]) \
  do
    json_response(Search.search(params.merge(:type => ['subject']), nil))
  end


  Endpoint.get('/search/tree_view')
  .description("Find the tree view for a particular archival record")
  .params(["node_uri", String, "The URI of the archival record to find the tree view for"])
  .permissions([:view_all_records])
  .returns([200, "OK"],
           [404, "Not found"]) \
  do

    show_suppressed = !RequestContext.get(:enforce_suppression)
    show_published_only = current_user.username === User.PUBLIC_USERNAME

    node_info = JSONModel.parse_reference(params[:node_uri])

    raise RecordNotFound.new if node_info.nil?

    search_data = Solr.search("*:*", 1, 1,
                              JSONModel(:repository).id_for(node_info[:repository]),
                              ['tree_view'], show_suppressed, show_published_only, true, [],
                              [{
                                 :node_uri => params[:node_uri]
                               }.to_json])

    raise RecordNotFound.new if search_data["total_hits"] === 0

    json_response(search_data["results"][0])

  end

end
