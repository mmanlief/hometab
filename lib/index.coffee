Spine = require("spine/core")
utils = require("duality/utils")
{_} = require("underscore")
querystring = require("querystring")
session = require('session')

db = require("db")
require("spine-adapter/couch-ajax")

templates = require("duality/templates")

sortable = require("./sortable")
search = require("./search")
options = require("./options")

class User extends Spine.Model
	@configure "User", "id", "_id", "user_name", "pages", "options", "search_history"

	@extend Spine.Model.CouchAjax

	@visitedSort: (l, r) ->
		if(l.visited_count < r.visited_count) then 1 else -1

	@userOrderSort: (l, r) ->
		if(l.user_order > r.user_order) then 1 else -1

	@defaultOptions: ->
			sort_order: "user"
			remember_search: true

	@findPageByUrl: (pages, url) ->
		found = null
		pages.forEach (page) ->
			if(page.page_url == url)
				found = page
		return found

class UserEvents extends Spine.Module
	@extend Spine.Events

class Pages extends Spine.Controller
	events:
		"click .remove-container"	: "remove"
		"click .page-item-tooltip"	: "visit"
		"click .info-btn"			: "visit"

	elements:
		".page-item-tooltip"		: "titles"
		".info-btn"					: "infos"

	constructor: ->
		super
		if(!@item.page_title)
			@updateTitle()

	template: (item) ->
		templates.render("template_page.html", {}, item)

	render: =>
		@replace($(@template(@item)))
		@titles.tooltip()
		@infos.tooltip()
		@

	visit: (e) ->
		e.preventDefault()
		if(!@item.visited_count)
			@item.visited_count = 0
		@item.visited_count = @item.visited_count + 1
		@user.save()
		UserEvents.trigger("visit")
		@redirectAfterSave()
		return false;

	redirectAfterSave: ->
		if(Spine.CouchAjax.pending)
			@delay(->
				@redirectAfterSave(@item)
			, 50)
		else
			window.location.href = @item.page_url


	updateTitle: ->
		$.ajax({
			url: "/magick/title?url=" + querystring.escape(@item.page_url),
			success: (data) =>
				@item.page_title = data
				@user.save()
		})

	remove: =>
		UserEvents.trigger("remove", @item)


class PagesApp extends Spine.Controller
	user: null
	sortable: null
	search: null
	options: null

	elements:
		"#pages_grid"			: "items"
		"#add_page_modal"		: "addPageModal"
		"#user_options_modal"	: "userOptionsModal"
		"#dnd_lock"				: "dndLock"
		"#trash_item"			: "trashItem"
		"#add_page_item"		: "addPageItem"

	constructor: ->
		super
		UserEvents.bind("remove", @removeOne)
		UserEvents.bind("visit", @render)
		UserEvents.bind("add", @addOne)
		UserEvents.bind("optionsChanged", @render)
		jQuery.event.props.push('dataTransfer')
		jQuery(window).on('drop', @dropped)
		@fetchUser()
		window.onbeforeunload = ->
			if Spine.CouchAjax.pending
				'''Data is still being sent to the server; 
				you may lose unsaved changes if you close the page.'''
		@centerModal(@userOptionsModal)
		@centerModal(@addPageModal)
		@handleQueryString()
		jQuery(window).resize(jQuery.throttle(100, @setGridPositioning))

	fetchUser: =>
		if(@user == null)
			session.info (err, info) =>
				if(!err)
					userCtx = info.userCtx
					if(userCtx.name && userCtx.name != "")
						id = userCtx.name
						appdb = db.use(require('duality/core').getDBURL())
						appdb.getDoc id, (err, res) =>
							if(res)
								@user = User.fromJSON(res)
								User.refresh(res)
							else
								User.refresh(@user = User.create(
									id: id
									_id: id
									user_name: id
									pages: []
									options: User.defaultOptions
									search_history: []
								))
							@render()
							@sortable = new sortable.SortableController
								el: @el
								user: @user
							@sortable.setupSortable()
							@search = new search.SearchController
								el: @el
								user: @user
							@search.setupSearch()
							@options = new options.OptionsController
								el: @el
								user: @user
							appdb.changes
								include_docs: yes
								filter: "hometab/usermodel"
							, @handleChanges

	handleChanges: (err, resp) =>
		@user = User.fromJSON(resp.results[0].doc)
		@render()

	addOne: (page) =>
		view = new Pages(item: page, user: @user)
		@items.append(view.render().el)

	removeOne: (page) =>
		@user.pages.splice(@user.pages.indexOf(page), 1)
		@user.save()
		@items.find("a[data-page-url='" + page.page_url + "']").parent().parent().remove()

	addAll: =>
		user.pages.forEach(@addOne)

	create: (url) =>
		userOrder = 0
		if(User.findPageByUrl(@user.pages, url))
			alert(url + " already added.")
		else
			if(@user.pages.length > 0)
				userOrder = jQuery(@user.pages.sort(User.userOrderSort)).last()[0].user_order + 1
			page = page_url: url, visited_count: 0, user_order: userOrder
			@user.pages.push(page)
			@user.save()
			UserEvents.trigger("add", page)

	render: =>
		pages = @sort(@user.pages)
		@items.empty();
		pages.forEach(@addOne)
		@setGridPositioning()

	sort: (pages) =>
		if(@user.options.sort_order == "visited")
			return pages.sort(User.visitedSort)
		else
			return pages.sort(User.userOrderSort)

	dropped: (e) =>
		e.preventDefault()
		if(e.dataTransfer)
			url = e.dataTransfer.getData("url")
			if(url != "")
				@create(url)

	centerModal: (modal) =>
		modal.css({
			'width': 'auto',
			'margin-left': ->
				-(modal.width() / 2)
			,'height': 'auto',
			'margin-top': ->
				-(modal.height() /2)
		})

	handleQueryString: ->
		url = window.location.href
		if(-1 != url.indexOf('?u='))
			qs = querystring.parse(url.split('?')[1])
			if(qs.u)
				@create(querystring.unescape(qs.u))

	setGridPositioning: ->
		gridItems = jQuery("#pages_outer div[class*='grid-item']")
		windowWidth = jQuery(window).width() - 10
		itemWidth = gridItems.first().width() + 8
		itemsPerRow = Math.floor(windowWidth / itemWidth)
		itemCount = Math.min(itemsPerRow, gridItems.length - 1)
		itemsWidth = itemWidth * itemCount
		extraSpace = windowWidth - itemsWidth
		jQuery("#pages_outer").css('padding-left', (extraSpace / 2) - 7)

module.exports.App = PagesApp
module.exports.User = User
module.exports.UserEvents = UserEvents