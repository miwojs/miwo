Configurator = require './Configurator'
Translator = require '../locale/Translator'


class Miwo

	@service: (name, service) ->
		Object.defineProperty @prototype, name,
			configurable: yes
			get:() -> @service(service || name)
		return

	# @property {Element}
	body: null

	# @property {String}
	baseUrl: ''

	# @property {Miwo.http.RequestManager}
	http: @service 'http'

	# @property {Miwo.http.RequestManager}
	cookie: @service 'cookie'

	# @property {Miwo.app.FlashNotificator}
	flash: @service 'flash'

	# @property {Miwo.component.ZIndexManager}
	zIndexMgr: @service 'zIndexMgr'

	# @property {Miwo.data.StoreManager}
	storeMgr: @service 'storeMgr'

	# @property {Miwo.data.ProxyManager}
	proxyMgr: @service 'proxyMgr'

	# @property {Miwo.data.EntityManager}
	entityMgr: @service 'entityMgr'

	# @property {Miwo.component.ComponentManager}
	componentMgr: @service 'componentMgr'

	# @property {Miwo.component.StateManager}
	componentStateMgr: @service 'componentStateMgr'

	# @property {Miwo.component.ComponentSelector}
	componentSelector: @service 'componentSelector'

	# @property {Miwo.window.WindowManager}
	windowMgr: @service 'windowMgr'

	# @property {Miwo.app.Application}
	application: @service 'application'

	# @property {Miwo.locale.Translator}
	translator: null

	# @property {Miwo.di.Injector}
	injector: null

	# @property Object
	extensions: null


	constructor: ->
		@ready () => @body = document.getElementsByTagName('body')[0];
		@extensions = {}
		@translator = new Translator()
		return


	# Register ready callback
	# @param {Function}
	ready: (callback) ->
		window.on('domready', callback)
		return

	# Translate key by translator
	# @param {String} key
	tr: (key) ->
		return @translator.get(key)


	# Require file by ajax and evaluate it
	# @param {String} file
	require: (file) ->
		data = miwo.http.read(@baseUrl+file+"?t="+(new Date().getTime()))
		try
			eval(data)
		catch e
			throw new Error("Cant require file #{file}, data are not evaluable. Reason #{e.getMessage()}")
		return


	# Redirect application to new request
	# @param {String} code
	# @param {Object} params
	redirect: (code, params) ->
		@application.redirect(code, params)
		return


	# Get component by id
	# @param {String}
	# @return {Miwo.component.Component}
	get: (id) ->
		return @componentMgr.get(id)


	# Make async callback call
	# @param {Function} callback
	# @return int
	async: (callback) ->
		return setTimeout ()=>
			callback()
			return
		,1


	# Find one component
	# @param {String}
	# @return {Miwo.component.Component}
	query: (selector) ->
		for component in @componentMgr.roots
			if component.isContainer
				result = @componentSelector.query(selector, component)
				if result then return result
			else if component.is(selector)
				return component
		return null


	# Find more components
	# @param {String}
	# @return {[Miwo.component.Component]}
	queryAll: (selector) ->
		results = []
		for component in @componentMgr.roots
			if component.isContainer
				results.append(@componentSelector.queryAll(selector, component))
			else if component.is(selector)
				results.push(component)
		return results


	# Get service from injector
	# @param {String} name
	# @returns {Object}
	service: (name) ->
		return @injector.get(name)


	# Get store
	# @param {String} name
	# @returns {Miwo.data.Store}
	store: (name) ->
		return @storeMgr.get(name)


	# Get store
	# @param {String} name
	# @returns {Miwo.data.Store}
	proxy: (name) ->
		return @proxyMgr.get(name)


	# Register DI extension class
	# @param {String} name Unique name of extension
	# @param {Miwo.di.InjectorExtension} extension Extension class
	registerExtension: (name, extension) ->
		@extensions[name] = extension
		return


	# Creates default configurator
	# @returns {Miwo.bootstrap.Configurator}
	createConfigurator: () ->
		configurator = new Configurator(this)
		for name,extension of @extensions
			configurator.setExtension(name, new extension())
		return configurator


	# Set injector (called by Configurator)
	# @param {Miwo.di.Injector}
	setInjector: (@injector) ->
		@injector.set('translator', @translator)
		for name, service of injector.globals
			Miwo.service(name, service) # create service getter
		return


	init: (onInit)->
		if @injector then return @injector
		configurator = @createConfigurator()
		onInit(configurator) if onInit
		injector = configurator.createInjector()
		return injector


# global object
module.exports = new Miwo