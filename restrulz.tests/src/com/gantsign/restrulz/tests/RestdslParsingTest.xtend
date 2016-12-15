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

import com.gantsign.restrulz.restdsl.Model
import com.gantsign.restrulz.restdsl.PathParam
import com.gantsign.restrulz.restdsl.PathParamRef
import com.gantsign.restrulz.restdsl.RequestHandler
import com.gantsign.restrulz.restdsl.StaticPathElement
import com.gantsign.restrulz.restdsl.StringRestriction
import com.google.inject.Inject
import org.eclipse.xtext.junit4.InjectWith
import org.eclipse.xtext.junit4.XtextRunner
import org.eclipse.xtext.junit4.util.ParseHelper
import org.junit.Test
import org.junit.runner.RunWith

import static org.junit.Assert.*

@RunWith(XtextRunner)
@InjectWith(RestdslInjectorProvider)
class RestdslParsingTest {

	@Inject
	ParseHelper<Model> parseHelper

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

		val lengthRange = stringRestriction.length.range
		assertEquals(1, lengthRange.start)
		assertEquals(100, lengthRange.end)
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
	def void parsePathScope() {
		val result = parseHelper.parse('''
			path /person/{id} : person-ws {

			}
		''')
		assertNotNull(result)

		var pathScope = result.pathScopes.get(0)

		assertEquals("person-ws", pathScope.name)

		var pathElements = pathScope.path.elements
		assertEquals(2, pathElements.size)

		var elem1 = pathElements.get(0).element
		assertTrue(elem1 instanceof StaticPathElement);
		var staticElement = elem1 as StaticPathElement
		assertEquals("person", staticElement.value)

		var elem2 = pathElements.get(1).element
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

		val lengthRange = stringRestriction.length.range
		assertEquals(36, lengthRange.start)
		assertEquals(36, lengthRange.end)

		// validate path
		var pathScope = result.pathScopes.get(0)

		assertEquals("person-ws", pathScope.name)

		var pathElements = pathScope.path.elements
		assertEquals(2, pathElements.size)

		var elem1 = pathElements.get(0).element
		assertTrue(elem1 instanceof StaticPathElement);
		var staticElement = elem1 as StaticPathElement
		assertEquals("person", staticElement.value)

		var elem2 = pathElements.get(1).element
		assertTrue(elem2 instanceof PathParam);
		var pathParam = elem2 as PathParam
		assertEquals("id", pathParam.name)
		assertEquals("uuid", pathParam.type.name)
	}

	@Test
	def void parseGet() {
		val result = parseHelper.parse('''
			path /person/{id} : person-ws {
				GET -> get-person()
			}
		''')
		assertNotNull(result)

		var pathScope = result.pathScopes.get(0)

		assertEquals("person-ws", pathScope.name)

		var pathElements = pathScope.path.elements
		assertEquals(2, pathElements.size)

		var elem1 = pathElements.get(0).element
		assertTrue(elem1 instanceof StaticPathElement);
		var staticElement = elem1 as StaticPathElement
		assertEquals("person", staticElement.value)

		var elem2 = pathElements.get(1).element
		assertTrue(elem2 instanceof PathParam);
		var pathParam = elem2 as PathParam
		assertEquals("id", pathParam.name)
		assertNull(pathParam.type)

		var mappings = pathScope.mappings

		var mapping = mappings.get(0).mapping
		assertTrue(mapping instanceof RequestHandler)
		var requestHandler = mapping as RequestHandler
		var method = requestHandler.method
		assertEquals("GET", method.name)
		assertEquals("get-person", requestHandler.name)
		assertEquals(0, requestHandler.parameters.size)
	}

	@Test
	def void parseGetWithParam() {
		val result = parseHelper.parse('''
			path /person/{id} : person-ws {
				GET -> get-person(/id)
			}
		''')
		assertNotNull(result)

		var pathScope = result.pathScopes.get(0)

		assertEquals("person-ws", pathScope.name)

		var pathElements = pathScope.path.elements
		assertEquals(2, pathElements.size)

		var elem1 = pathElements.get(0).element
		assertTrue(elem1 instanceof StaticPathElement);
		var staticElement = elem1 as StaticPathElement
		assertEquals("person", staticElement.value)

		var elem2 = pathElements.get(1).element
		assertTrue(elem2 instanceof PathParam);
		var pathParam = elem2 as PathParam
		assertEquals("id", pathParam.name)
		assertNull(pathParam.type)

		var mappings = pathScope.mappings

		var mapping = mappings.get(0).mapping
		assertTrue(mapping instanceof RequestHandler)
		var requestHandler = mapping as RequestHandler
		var method = requestHandler.method
		assertEquals("GET", method.name)
		assertEquals("get-person", requestHandler.name)

		var param = requestHandler.parameters.get(0).parameter
		assertTrue(param instanceof PathParamRef)
		var pathParamRef = param as PathParamRef
		assertEquals("id", pathParamRef.ref.name)
	}

	@Test
	def void parsePut() {
		val result = parseHelper.parse('''
			path /person/{id} : person-ws {
				PUT -> update-person()
			}
		''')
		assertNotNull(result)

		var pathScope = result.pathScopes.get(0)

		assertEquals("person-ws", pathScope.name)

		var pathElements = pathScope.path.elements
		assertEquals(2, pathElements.size)

		var elem1 = pathElements.get(0).element
		assertTrue(elem1 instanceof StaticPathElement);
		var staticElement = elem1 as StaticPathElement
		assertEquals("person", staticElement.value)

		var elem2 = pathElements.get(1).element
		assertTrue(elem2 instanceof PathParam);
		var pathParam = elem2 as PathParam
		assertEquals("id", pathParam.name)
		assertNull(pathParam.type)

		var mappings = pathScope.mappings

		var mapping = mappings.get(0).mapping
		assertTrue(mapping instanceof RequestHandler)
		var requestHandler = mapping as RequestHandler
		var method = requestHandler.method
		assertEquals("PUT", method.name)
		assertEquals("update-person", requestHandler.name)
		assertEquals(0, requestHandler.parameters.size)
	}

	@Test
	def void parsePost() {
		val result = parseHelper.parse('''
			path /person/{id} : person-ws {
				POST -> add-person()
			}
		''')
		assertNotNull(result)

		var pathScope = result.pathScopes.get(0)

		assertEquals("person-ws", pathScope.name)

		var pathElements = pathScope.path.elements
		assertEquals(2, pathElements.size)

		var elem1 = pathElements.get(0).element
		assertTrue(elem1 instanceof StaticPathElement);
		var staticElement = elem1 as StaticPathElement
		assertEquals("person", staticElement.value)

		var elem2 = pathElements.get(1).element
		assertTrue(elem2 instanceof PathParam);
		var pathParam = elem2 as PathParam
		assertEquals("id", pathParam.name)
		assertNull(pathParam.type)

		var mappings = pathScope.mappings

		var mapping = mappings.get(0).mapping
		assertTrue(mapping instanceof RequestHandler)
		var requestHandler = mapping as RequestHandler
		var method = requestHandler.method
		assertEquals("POST", method.name)
		assertEquals("add-person", requestHandler.name)
		assertEquals(0, requestHandler.parameters.size)
	}

	@Test
	def void parseDelete() {
		val result = parseHelper.parse('''
			path /person/{id} : person-ws {
				DELETE -> delete-person()
			}
		''')
		assertNotNull(result)

		var pathScope = result.pathScopes.get(0)

		assertEquals("person-ws", pathScope.name)

		var pathElements = pathScope.path.elements
		assertEquals(2, pathElements.size)

		var elem1 = pathElements.get(0).element
		assertTrue(elem1 instanceof StaticPathElement);
		var staticElement = elem1 as StaticPathElement
		assertEquals("person", staticElement.value)

		var elem2 = pathElements.get(1).element
		assertTrue(elem2 instanceof PathParam);
		var pathParam = elem2 as PathParam
		assertEquals("id", pathParam.name)
		assertNull(pathParam.type)

		var mappings = pathScope.mappings

		var mapping = mappings.get(0).mapping
		assertTrue(mapping instanceof RequestHandler)
		var requestHandler = mapping as RequestHandler
		var method = requestHandler.method
		assertEquals("DELETE", method.name)
		assertEquals("delete-person", requestHandler.name)
		assertEquals(0, requestHandler.parameters.size)
	}
}
