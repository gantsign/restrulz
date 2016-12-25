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
import com.gantsign.restrulz.restdsl.IntegerType
import com.gantsign.restrulz.restdsl.PathParam
import com.gantsign.restrulz.restdsl.PathParamRef
import com.gantsign.restrulz.restdsl.RequestHandler
import com.gantsign.restrulz.restdsl.Specification
import com.gantsign.restrulz.restdsl.StaticPathElement
import com.gantsign.restrulz.restdsl.StringType
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
	def void parseSpecification() {
		val spec = parseHelper.parse('''
			specification people {}
		''')
		assertNotNull(spec)

		assertEquals("people", spec.name)
	}

	@Test
	def void parseSpecificationWithDoc() {
		val spec = parseHelper.parse('''
			@doc {
				title: "test1"
				description: "test2
				a\t
					b"
				version: "test3"
			}
			specification people {}
		''')
		assertNotNull(spec)

		assertEquals("people", spec.name)
		assertEquals("test1", spec.doc?.title)
		assertEquals("test2\n\ta\t\n\t\tb", spec.doc?.description)
		assertEquals("test3", spec.doc?.version)
	}

	@Test
	def void parseSpecificationWithDocWrap() {
		val spec = parseHelper.parse('''
			@doc {
				title: "test1"
				description: "
					test2
				a\t
					b
				"
				version: "test3"
			}
			specification people {}
		''')
		assertNotNull(spec)

		assertEquals("people", spec.name)
		assertEquals("test1", spec.doc?.title)
		assertEquals("\n\t\ttest2\n\ta\t\n\t\tb\n\t", spec.doc?.description)
		assertEquals("test3", spec.doc?.version)
	}

	@Test
	def void parseStringType() {
		val spec = parseHelper.parse('''
			specification people {
				type name : string ^[\p{Alpha}\']+$ length [1..100]
			}
		''')
		assertNotNull(spec)

		assertEquals("people", spec.name)

		val type = spec.simpleTypes.get(0)
		if (!(type instanceof StringType)) {
			fail("Unexpected type: " + type.class.name)
			return;
		}

		val stringType = type as StringType
		assertEquals("^[\\p{Alpha}\\']+$", stringType.pattern)
		assertEquals(1, stringType.minLength)
		assertEquals(100, stringType.maxLength)
	}

	@Test
	def void parseIntegerType() {
		val spec = parseHelper.parse('''
			specification people {
				type age : int [0..150]
			}
		''')
		assertNotNull(spec)

		assertEquals("people", spec.name)

		val type = spec.simpleTypes.get(0)
		if (!(type instanceof IntegerType)) {
			fail("Unexpected type: " + type.class.name)
			return;
		}

		val integerType = (type as IntegerType)
		assertEquals(0, integerType.minimum)
		assertEquals(150, integerType.maximum)
	}

	@Test
	def void parseCustomDefaultType() {
		val spec = parseHelper.parse('''
			specification people {
				type default-type : string ^abc$ length [3..3]
			}
		''')
		assertNotNull(spec)

		assertEquals("people", spec.name)

		val type = spec.simpleTypes.get(0)
		if (!(type instanceof StringType)) {
			fail("Unexpected type: " + type.class.name)
			return;
		}

		val stringType = type as StringType
		assertEquals("^abc$", stringType.pattern)
		assertEquals(3, stringType.minLength)
		assertEquals(3, stringType.maxLength)
	}

	@Test
	def void parseClassType() {
		val spec = parseHelper.parse('''
			specification people {
				class person {
					first-name

					last-name
				}
			}
		''')
		assertNotNull(spec)

		assertEquals("people", spec.name)

		val clazz = spec.classTypes.get(0)

		assertEquals("person", clazz.name)

		val properties = clazz.properties
		assertEquals(2, properties.size)

		var prop1 = properties.get(0)
		assertEquals("first-name", prop1.name)
		assertNull(prop1.type)
		assertFalse(prop1.isAllowEmpty)
		assertFalse(prop1.isAllowNull)

		var prop2 = properties.get(1)
		assertEquals("last-name", prop2.name)
		assertNull(prop2.type)
		assertFalse(prop2.isAllowEmpty)
		assertFalse(prop2.isAllowNull)
	}

	@Test
	def void parseClassTypeRestrictedProperties() {
		val spec = parseHelper.parse('''
			specification people {
				type name : string ^[\p{Alpha}\']+$ length [1..100]

				class person {
					first-name : name

					last-name : name
				}
			}
		''')
		assertNotNull(spec)

		assertEquals("people", spec.name)

		val clazz = spec.classTypes.get(0)

		assertEquals("person", clazz.name)

		val properties = clazz.properties
		assertEquals(2, properties.size)

		var prop1 = properties.get(0)
		assertEquals("first-name", prop1.name)
		assertEquals("name", prop1.type.name)
		assertFalse(prop1.isAllowEmpty)
		assertFalse(prop1.isAllowNull)

		var prop2 = properties.get(1)
		assertEquals("last-name", prop2.name)
		assertEquals("name", prop2.type.name)
		assertFalse(prop2.isAllowEmpty)
		assertFalse(prop2.isAllowNull)
	}

	@Test
	def void parseClassTypeWithBoolean() {
		val spec = parseHelper.parse('''
			specification people {
				class person {
					employed : boolean
				}
			}
		''')
		assertNotNull(spec)

		assertEquals("people", spec.name)

		val clazz = spec.classTypes.get(0)

		assertEquals("person", clazz.name)

		val properties = clazz.properties
		assertEquals(1, properties.size)

		var prop1 = properties.get(0)
		assertEquals("employed", prop1.name)
		assertEquals("boolean", prop1.fixedType)
		assertFalse(prop1.isAllowEmpty)
		assertFalse(prop1.isAllowNull)
		assertFalse(prop1.isArray)
	}

	@Test
	def void parseClassTypeRestrictedOptionalProperties() {
		val spec = parseHelper.parse('''
			specification people {
				type name : string ^[\p{Alpha}\']+$ length [1..100]
				type age : int [0..150]

				class address {}
				class person {
					first-name : name
					last-name : name | empty
					age : age | null
					address : address | null
				}
			}
		''')
		assertNotNull(spec)

		assertEquals("people", spec.name)

		val classTypes = spec.classTypes
		assertEquals(2, classTypes.size)

		val class1 = classTypes.get(0)
		assertEquals("address", class1.name)

		val class2 = classTypes.get(1)
		assertEquals("person", class2.name)

		val properties = class2.properties
		assertEquals(4, properties.size)

		var prop1 = properties.get(0)
		assertEquals("first-name", prop1.name)
		assertEquals("name", prop1.type.name)
		assertFalse(prop1.isAllowEmpty)
		assertFalse(prop1.isAllowNull)

		var prop2 = properties.get(1)
		assertEquals("last-name", prop2.name)
		assertEquals("name", prop2.type.name)
		assertTrue(prop2.isAllowEmpty)
		assertFalse(prop2.isAllowNull)

		var prop3 = properties.get(2)
		assertEquals("age", prop3.name)
		assertEquals("age", prop3.type.name)
		assertFalse(prop3.isAllowEmpty)
		assertTrue(prop3.isAllowNull)

		var prop4 = properties.get(3)
		assertEquals("address", prop4.name)
		assertEquals("address", prop4.type.name)
		assertFalse(prop4.isAllowEmpty)
		assertTrue(prop4.isAllowNull)
	}

	@Test
	def void parseClassTypeArrayProperty() {
		val spec = parseHelper.parse('''
			specification people {
				class address {}
				class person {
					addresses : address[]
				}
			}
		''')
		assertNotNull(spec)

		assertEquals("people", spec.name)

		val classTypes = spec.classTypes
		val class1 = classTypes.get(0)
		assertEquals("address", class1.name)

		val class2 = classTypes.get(1)
		assertEquals("person", class2.name)

		val properties = class2.properties
		assertEquals(1, properties.size)

		var prop1 = properties.get(0)
		assertEquals("addresses", prop1.name)
		assertEquals("address", prop1.type.name)
		assertTrue(prop1.isArray)
	}

	@Test
	def void parseResponse() {
		val spec = parseHelper.parse('''
			specification people {
				class person {}

				response get-person-success : ok person
			}
		''')
		assertNotNull(spec)

		assertEquals("people", spec.name)

		var response = spec.responses.get(0)
		assertEquals("get-person-success", response.name)
		var detail = response.detail

		assertEquals(HTTP_200, detail.status)
		assertEquals("person", detail.body.name)
	}

	@Test
	def void parsePathScope() {
		val spec = parseHelper.parse('''
			specification people {
				path /person/{id} : person-ws {

				}
			}
		''')
		assertNotNull(spec)

		assertEquals("people", spec.name)

		var pathScope = spec.pathScopes.get(0)

		assertEquals("person-ws", pathScope.name)

		var pathElements = pathScope.path.elements
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

	@Test
	def void parsePathScopeRoot() {
		val spec = parseHelper.parse('''
			specification people {
				path / : person-ws {

				}
			}
		''')
		assertNotNull(spec)

		assertEquals("people", spec.name)

		var pathScope = spec.pathScopes.get(0)

		assertEquals("person-ws", pathScope.name)

		var pathElements = pathScope.path.elements
		assertEquals(0, pathElements.size)
	}

	def void parsePathScopeRestrictedId() {
		val spec = parseHelper.parse('''
			specification people {
				type uuid : string ^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$ length [36..36]

				path /person/{id : uuid} : person-ws {

				}
			}
		''')
		assertNotNull(spec)

		assertEquals("people", spec.name)

		// validate type
		val type = spec.simpleTypes.get(0)

		if (!(type instanceof StringType)) {
			fail("Unexpected type: " + type.class.name)
			return;
		}

		val stringType = type as StringType
		assertEquals("^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", stringType.pattern)
		assertEquals(36, stringType.minLength)
		assertEquals(36, stringType.maxLength)

		// validate path
		var pathScope = spec.pathScopes.get(0)

		assertEquals("person-ws", pathScope.name)

		var pathElements = pathScope.path.elements
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
		val spec = parseHelper.parse('''
			specification people {
				class person {}

				response get-person-success : ok person

				path /person/{id} : person-ws {
					get -> get-person() : get-person-success
				}
			}
		''')
		assertNotNull(spec)

		assertEquals("people", spec.name)

		var pathScope = spec.pathScopes.get(0)

		assertEquals("person-ws", pathScope.name)

		var pathElements = pathScope.path.elements
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
		val spec = parseHelper.parse('''
			specification people {
				class person {}

				response get-person-success : ok person

				path /person/{id} : person-ws {
					get -> get-person(/id) : get-person-success
				}
			}
		''')
		assertNotNull(spec)

		assertEquals("people", spec.name)

		var pathScope = spec.pathScopes.get(0)

		assertEquals("person-ws", pathScope.name)

		var pathElements = pathScope.path.elements
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
		val spec = parseHelper.parse('''
			specification people {
				class person {}

				response update-person-success : ok person

				path /person/{id} : person-ws {
					put -> update-person() : update-person-success
				}
			}
		''')
		assertNotNull(spec)

		assertEquals("people", spec.name)

		var pathScope = spec.pathScopes.get(0)

		assertEquals("person-ws", pathScope.name)

		var pathElements = pathScope.path.elements
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
		val spec = parseHelper.parse('''
			specification people {
				class person {
					first-name : name

					last-name : name
				}

				response update-person-success : ok person

				path /person/{id} : person-ws {
					put -> update-person(/id, *person) : update-person-success
				}
			}
		''')
		assertNotNull(spec)

		assertEquals("people", spec.name)

		var pathScope = spec.pathScopes.get(0)

		assertEquals("person-ws", pathScope.name)

		var pathElements = pathScope.path.elements
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
		val spec = parseHelper.parse('''
			specification people {
				class person {}

				response add-person-success : ok person

				path /person/{id} : person-ws {
					post -> add-person() : add-person-success
				}
			}
		''')
		assertNotNull(spec)

		assertEquals("people", spec.name)

		var pathScope = spec.pathScopes.get(0)

		assertEquals("person-ws", pathScope.name)

		var pathElements = pathScope.path.elements
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
		val spec = parseHelper.parse('''
			specification people {
				class person {}

				response delete-person-success : ok person

				path /person/{id} : person-ws {
					delete -> delete-person() : delete-person-success
				}
			}
		''')
		assertNotNull(spec)

		assertEquals("people", spec.name)

		var pathScope = spec.pathScopes.get(0)

		assertEquals("person-ws", pathScope.name)

		var pathElements = pathScope.path.elements
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
