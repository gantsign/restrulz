/*
 * Copyright 2016 GantSign Ltd. All Rights Reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package com.gantsign.restrulz.tests

import com.gantsign.restrulz.restdsl.BodyTypeRef
import com.gantsign.restrulz.restdsl.ClassType
import com.gantsign.restrulz.restdsl.PathParam
import com.gantsign.restrulz.restdsl.PathParamRef
import com.gantsign.restrulz.restdsl.RequestHandler
import com.gantsign.restrulz.restdsl.Specification
import com.gantsign.restrulz.restdsl.StaticPathElement
import com.gantsign.restrulz.restdsl.StringRestriction
import com.google.inject.Inject
import org.eclipse.xtext.junit4.InjectWith
import org.eclipse.xtext.junit4.XtextRunner
import org.eclipse.xtext.junit4.util.ParseHelper
import org.junit.Test
import org.junit.runner.RunWith

import static com.gantsign.restrulz.restdsl.HttpMethod.*
import static com.gantsign.restrulz.restdsl.SuccessWithBodyStatus.*
import static org.junit.Assert.*

@RunWith(XtextRunner)
@InjectWith(RestdslInjectorProvider)
class RestdslParsingTest {

	@Inject
	ParseHelper<Specification> parseHelper

	@Test
	def void parseStringType() {
		val result = parseHelper.parse('''
			type name : string ^[\p{Alpha}\']+$ length [1..100]
		''')
		assertNotNull(result)

		val type = result.simpleTypes.get(0)

		val restriction = type.restriction
		assertTrue(restriction instanceof StringRestriction)
		val stringRestriction = (restriction as StringRestriction)

		val pattern = stringRestriction.pattern
		assertEquals("^[\\p{Alpha}\\']+$", pattern)

		val lengthRange = stringRestriction.length
		assertEquals(1, lengthRange.start)
		assertEquals(100, lengthRange.end)
	}

	@Test
	def void parseCustomDefaultType() {
		val result = parseHelper.parse('''
			type default-type : string ^abc$ length [3..3]
		''')
		assertNotNull(result)

		val type = result.simpleTypes.get(0)

		val restriction = type.restriction
		assertTrue(restriction instanceof StringRestriction)
		val stringRestriction = (restriction as StringRestriction)

		val pattern = stringRestriction.pattern
		assertEquals("^abc$", pattern)

		val lengthRange = stringRestriction.length
		assertEquals(3, lengthRange.start)
		assertEquals(3, lengthRange.end)
	}

	@Test
	def void parseClassType() {
		val result = parseHelper.parse('''
			class person {
				first-name

				last-name
			}
		''')
		assertNotNull(result)

		val clazz = result.classTypes.get(0)

		assertEquals("person", clazz.name)

		val properties = clazz.properties
		assertEquals(2, properties.size)

		var prop1 = properties.get(0)
		assertEquals("first-name", prop1.name)
		assertNull(prop1.type)

		var prop2 = properties.get(1)
		assertEquals("last-name", prop2.name)
		assertNull(prop2.type)
	}

	@Test
	def void parseClassTypeRestrictedProperties() {
		val result = parseHelper.parse('''
			type name : string ^[\p{Alpha}\']+$ length [1..100]

			class person {
				first-name : name

				last-name : name
			}
		''')
		assertNotNull(result)

		val clazz = result.classTypes.get(0)

		assertEquals("person", clazz.name)

		val properties = clazz.properties
		assertEquals(2, properties.size)

		var prop1 = properties.get(0)
		assertEquals("first-name", prop1.name)
		assertEquals("name", prop1.type.name)

		var prop2 = properties.get(1)
		assertEquals("last-name", prop2.name)
		assertEquals("name", prop2.type.name)
	}

	@Test
	def void parseResponse() {
		val result = parseHelper.parse('''
			class person {}

			response get-person-success : ok person
		''')
		assertNotNull(result)

		var response = result.responses.get(0)
		assertEquals("get-person-success", response.name)
		var detail = response.detail

		assertEquals(HTTP_200, detail.status)
		assertEquals("person", detail.body.name)
	}

	@Test
	def void parsePathScope() {
		val result = parseHelper.parse('''
			path /person/{id} : person-ws {

			}
		''')
		assertNotNull(result)

		var pathScope = result.pathScopes.get(0)

		assertEquals("person-ws", pathScope.name)

		var pathElements = pathScope.path
		assertEquals(2, pathElements.size)

		var elem1 = pathElements.get(0)
		assertTrue(elem1 instanceof StaticPathElement);
		var staticElement = elem1 as StaticPathElement
		assertEquals("person", staticElement.value)

		var elem2 = pathElements.get(1)
		assertTrue(elem2 instanceof PathParam);
		var pathParam = elem2 as PathParam
		assertEquals("id", pathParam.name)
		assertNull(pathParam.type)
	}

	def void parsePathScopeRestrictedId() {
		val result = parseHelper.parse('''
			type uuid : string ^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$ length [36..36]

			path /person/{id : uuid} : person-ws {

			}
		''')
		assertNotNull(result)

		// validate type
		val type = result.simpleTypes.get(0)

		val restriction = type.restriction
		assertTrue(restriction instanceof StringRestriction)
		val stringRestriction = (restriction as StringRestriction)

		val pattern = stringRestriction.pattern
		assertEquals("^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", pattern)

		val lengthRange = stringRestriction.length
		assertEquals(36, lengthRange.start)
		assertEquals(36, lengthRange.end)

		// validate path
		var pathScope = result.pathScopes.get(0)

		assertEquals("person-ws", pathScope.name)

		var pathElements = pathScope.path
		assertEquals(2, pathElements.size)

		var elem1 = pathElements.get(0)
		assertTrue(elem1 instanceof StaticPathElement);
		var staticElement = elem1 as StaticPathElement
		assertEquals("person", staticElement.value)

		var elem2 = pathElements.get(1)
		assertTrue(elem2 instanceof PathParam);
		var pathParam = elem2 as PathParam
		assertEquals("id", pathParam.name)
		assertEquals("uuid", pathParam.type.name)
	}

	@Test
	def void parseGet() {
		val result = parseHelper.parse('''
			class person {}

			response get-person-success : ok person

			path /person/{id} : person-ws {
				get -> get-person() : get-person-success
			}
		''')
		assertNotNull(result)

		var pathScope = result.pathScopes.get(0)

		assertEquals("person-ws", pathScope.name)

		var pathElements = pathScope.path
		assertEquals(2, pathElements.size)

		var elem1 = pathElements.get(0)
		assertTrue(elem1 instanceof StaticPathElement);
		var staticElement = elem1 as StaticPathElement
		assertEquals("person", staticElement.value)

		var elem2 = pathElements.get(1)
		assertTrue(elem2 instanceof PathParam);
		var pathParam = elem2 as PathParam
		assertEquals("id", pathParam.name)
		assertNull(pathParam.type)

		var mappings = pathScope.mappings

		var mapping = mappings.get(0)
		assertTrue(mapping instanceof RequestHandler)
		var requestHandler = mapping as RequestHandler
		assertEquals(GET, requestHandler.method)
		assertEquals("get-person", requestHandler.name)
		assertEquals(0, requestHandler.parameters.size)

		var response = requestHandler.response
		assertEquals("get-person-success", response.name)
		var detail = response.detail
		assertEquals(HTTP_200, detail.status)
		assertEquals("person", detail.body.name)
	}

	@Test
	def void parseGetWithParam() {
		val result = parseHelper.parse('''
			class person {}

			response get-person-success : ok person

			path /person/{id} : person-ws {
				get -> get-person(/id) : get-person-success
			}
		''')
		assertNotNull(result)

		var pathScope = result.pathScopes.get(0)

		assertEquals("person-ws", pathScope.name)

		var pathElements = pathScope.path
		assertEquals(2, pathElements.size)

		var elem1 = pathElements.get(0)
		assertTrue(elem1 instanceof StaticPathElement);
		var staticElement = elem1 as StaticPathElement
		assertEquals("person", staticElement.value)

		var elem2 = pathElements.get(1)
		assertTrue(elem2 instanceof PathParam);
		var pathParam = elem2 as PathParam
		assertEquals("id", pathParam.name)
		assertNull(pathParam.type)

		var mappings = pathScope.mappings

		var mapping = mappings.get(0)
		assertTrue(mapping instanceof RequestHandler)
		var requestHandler = mapping as RequestHandler
		assertEquals(GET, requestHandler.method)
		assertEquals("get-person", requestHandler.name)

		var param = requestHandler.parameters.get(0)
		assertTrue(param instanceof PathParamRef)
		var pathParamRef = param as PathParamRef
		assertEquals("id", pathParamRef.ref.name)

		var response = requestHandler.response
		assertEquals("get-person-success", response.name)
		var detail = response.detail
		assertEquals(HTTP_200, detail.status)
		assertEquals("person", detail.body.name)
	}

	@Test
	def void parsePut() {
		val result = parseHelper.parse('''
			class person {}

			response update-person-success : ok person

			path /person/{id} : person-ws {
				put -> update-person() : update-person-success
			}
		''')
		assertNotNull(result)

		var pathScope = result.pathScopes.get(0)

		assertEquals("person-ws", pathScope.name)

		var pathElements = pathScope.path
		assertEquals(2, pathElements.size)

		var elem1 = pathElements.get(0)
		assertTrue(elem1 instanceof StaticPathElement);
		var staticElement = elem1 as StaticPathElement
		assertEquals("person", staticElement.value)

		var elem2 = pathElements.get(1)
		assertTrue(elem2 instanceof PathParam);
		var pathParam = elem2 as PathParam
		assertEquals("id", pathParam.name)
		assertNull(pathParam.type)

		var mappings = pathScope.mappings

		var mapping = mappings.get(0)
		assertTrue(mapping instanceof RequestHandler)
		var requestHandler = mapping as RequestHandler
		assertEquals(PUT, requestHandler.method)
		assertEquals("update-person", requestHandler.name)
		assertEquals(0, requestHandler.parameters.size)

		var response = requestHandler.response
		assertEquals("update-person-success", response.name)
		var detail = response.detail
		assertEquals(HTTP_200, detail.status)
		assertEquals("person", detail.body.name)
	}

	@Test
	def void parsePutWithParams() {
		val result = parseHelper.parse('''
			class person {
				first-name : name

				last-name : name
			}

			response update-person-success : ok person

			path /person/{id} : person-ws {
				put -> update-person(/id, *person) : update-person-success
			}
		''')
		assertNotNull(result)

		var pathScope = result.pathScopes.get(0)

		assertEquals("person-ws", pathScope.name)

		var pathElements = pathScope.path
		assertEquals(2, pathElements.size)

		var elem1 = pathElements.get(0)
		assertTrue(elem1 instanceof StaticPathElement);
		var staticElement = elem1 as StaticPathElement
		assertEquals("person", staticElement.value)

		var elem2 = pathElements.get(1)
		assertTrue(elem2 instanceof PathParam);
		var pathParam = elem2 as PathParam
		assertEquals("id", pathParam.name)
		assertNull(pathParam.type)

		var mappings = pathScope.mappings

		var mapping = mappings.get(0)
		assertTrue(mapping instanceof RequestHandler)
		var requestHandler = mapping as RequestHandler
		assertEquals(PUT, requestHandler.method)
		assertEquals("update-person", requestHandler.name)

		assertEquals(2, requestHandler.parameters.size)

		var param1 = requestHandler.parameters.get(0)
		assertTrue(param1 instanceof PathParamRef)
		var pathParamRef = param1 as PathParamRef
		assertEquals("id", pathParamRef.ref.name)

		var param2 = requestHandler.parameters.get(1)
		assertTrue(param2 instanceof BodyTypeRef)
		var bodyTypeRef = param2 as BodyTypeRef
		assertTrue(bodyTypeRef.ref instanceof ClassType)
		var classType = bodyTypeRef.ref as ClassType
		assertEquals("person", classType.name)

		var response = requestHandler.response
		assertEquals("update-person-success", response.name)
		var detail = response.detail
		assertEquals(HTTP_200, detail.status)
		assertEquals("person", detail.body.name)
	}

	@Test
	def void parsePost() {
		val result = parseHelper.parse('''
			class person {}

			response add-person-success : ok person

			path /person/{id} : person-ws {
				post -> add-person() : add-person-success
			}
		''')
		assertNotNull(result)

		var pathScope = result.pathScopes.get(0)

		assertEquals("person-ws", pathScope.name)

		var pathElements = pathScope.path
		assertEquals(2, pathElements.size)

		var elem1 = pathElements.get(0)
		assertTrue(elem1 instanceof StaticPathElement);
		var staticElement = elem1 as StaticPathElement
		assertEquals("person", staticElement.value)

		var elem2 = pathElements.get(1)
		assertTrue(elem2 instanceof PathParam);
		var pathParam = elem2 as PathParam
		assertEquals("id", pathParam.name)
		assertNull(pathParam.type)

		var mappings = pathScope.mappings

		var mapping = mappings.get(0)
		assertTrue(mapping instanceof RequestHandler)
		var requestHandler = mapping as RequestHandler
		assertEquals(POST, requestHandler.method)
		assertEquals("add-person", requestHandler.name)
		assertEquals(0, requestHandler.parameters.size)

		var response = requestHandler.response
		assertEquals("add-person-success", response.name)
		var detail = response.detail
		assertEquals(HTTP_200, detail.status)
		assertEquals("person", detail.body.name)
	}

	@Test
	def void parseDelete() {
		val result = parseHelper.parse('''
			class person {}

			response delete-person-success : ok person

			path /person/{id} : person-ws {
				delete -> delete-person() : delete-person-success
			}
		''')
		assertNotNull(result)

		var pathScope = result.pathScopes.get(0)

		assertEquals("person-ws", pathScope.name)

		var pathElements = pathScope.path
		assertEquals(2, pathElements.size)

		var elem1 = pathElements.get(0)
		assertTrue(elem1 instanceof StaticPathElement);
		var staticElement = elem1 as StaticPathElement
		assertEquals("person", staticElement.value)

		var elem2 = pathElements.get(1)
		assertTrue(elem2 instanceof PathParam);
		var pathParam = elem2 as PathParam
		assertEquals("id", pathParam.name)
		assertNull(pathParam.type)

		var mappings = pathScope.mappings

		var mapping = mappings.get(0)
		assertTrue(mapping instanceof RequestHandler)
		var requestHandler = mapping as RequestHandler
		assertEquals(DELETE, requestHandler.method)
		assertEquals("delete-person", requestHandler.name)
		assertEquals(0, requestHandler.parameters.size)

		var response = requestHandler.response
		assertEquals("delete-person-success", response.name)
		var detail = response.detail
		assertEquals(HTTP_200, detail.status)
		assertEquals("person", detail.body.name)
	}
}
