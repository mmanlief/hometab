Spine = require("spine/core")
App = require("./index")
querystring = require("querystring")
require("spine-adapter/couch-ajax")

class SearchController extends Spine.Controller
	user: null

	elements:
		"#search_form"						: "searchForm"
		"#search_form input[type='text']"	: "searchInput"

	events:
		"submit #search_form"				: "doSearch"

	constructor: ->
		super
		App.UserEvents.bind("optionsChanged", @setupSearch)

	setupSearch: =>
		if(@user.options.remember_search)
			@searchInput.autocomplete
				source: @taSource()
				minLength: 0
			@searchInput.click =>
				@searchInput.autocomplete("search")
		else
			@user.search_history = []

	doSearch: (e) =>
		e.preventDefault()
		query = @searchInput.val()
		if(!@user.search_history)
			@user.search_history = []
		idx = @user.search_history.indexOf(query)
		if(-1 != idx)
			@user.search_history.splice(idx, 1)
		@user.search_history.splice(0, 0, query)
		@user.save()
		@doSearchAfterSave(query)


	doSearchAfterSave: (query) =>
		if(Spine.CouchAjax.pending)
			@delay(->
				@doSearchAfterSave(query)
			, 50)
		else
			window.location.href = "https://www.google.com/search?q=" + querystring.escape(query)

	taSource: =>
		@user.search_history

	taMatch: (item) ->
		-1 != item.indexOf(this.query)

module.exports.SearchController = SearchController