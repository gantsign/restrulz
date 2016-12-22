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

import com.gantsign.restrulz.restdsl.Specification
import com.google.gson.JsonParser
import com.google.inject.Inject
import org.eclipse.xtext.generator.IFileSystemAccess
import org.eclipse.xtext.generator.IGenerator2
import org.eclipse.xtext.generator.InMemoryFileSystemAccess
import org.eclipse.xtext.junit4.InjectWith
import org.eclipse.xtext.junit4.XtextRunner
import org.eclipse.xtext.junit4.util.ParseHelper
import org.junit.Test
import org.junit.runner.RunWith

import static org.junit.Assert.*

@RunWith(XtextRunner)
@InjectWith(RestdslInjectorProvider)
class RestdslGeneratorTest {

	@Inject
	IGenerator2 generator

	@Inject
	ParseHelper<Specification> parseHelper

	val schemaFile = IFileSystemAccess::DEFAULT_OUTPUT + "schema.json"

	def assertJsonEquals(String expected, String actual) {
		val parser = new JsonParser()
		val expectedJson = parser.parse(expected)
		val actualJson = parser.parse(actual)
		assertEquals(expectedJson, actualJson)
	}

	@Test
	def void generateSpecification() {
		val spec = parseHelper.parse('''
			specification people {}
		 ''')
		assertNotNull(spec)

		val fsa = new InMemoryFileSystemAccess()
		generator.doGenerate(spec.eResource, fsa, null)

		println(fsa.textFiles)
		assertEquals(1, fsa.textFiles.size)
		assertTrue(fsa.textFiles.containsKey(schemaFile))

		val expected = '''
		{
			"name": "people",
			"simple-types": [],
			"class-types":[],
			"responses":[],
			"path-scopes":[]
		}'''.toString

		val actual = fsa.textFiles.get(schemaFile).toString

		assertJsonEquals(expected, actual)
	}

	@Test
	def void generateStringType() {
		val spec = parseHelper.parse('''
			specification people {
				type name : string ^[\p{Alpha}\']+$ length [1..100]
			}
		 ''')
		assertNotNull(spec)

		val fsa = new InMemoryFileSystemAccess()
		generator.doGenerate(spec.eResource, fsa, null)

		println(fsa.textFiles)
		assertEquals(1, fsa.textFiles.size)
		assertTrue(fsa.textFiles.containsKey(schemaFile))

		val expected = '''
		{
			"name": "people",
			"simple-types": [
				{
					"name": "name",
					"kind": "string",
					"pattern": "^[\\p{Alpha}\\']+$",
					"min-length": 1,
					"max-length": 100
				}
			],
			"class-types":[],
			"responses":[],
			"path-scopes":[]
		}'''.toString

		val actual = fsa.textFiles.get(schemaFile).toString

		assertJsonEquals(expected, actual)
	}

	@Test
	def void generateClassType() {
		val spec = parseHelper.parse('''
			specification people {
				class person {
					first-name

					last-name
				}
			}
		''')
		assertNotNull(spec)

		val fsa = new InMemoryFileSystemAccess()
		generator.doGenerate(spec.eResource, fsa, null)

		println(fsa.textFiles)
		assertEquals(1, fsa.textFiles.size)
		assertTrue(fsa.textFiles.containsKey(schemaFile))

		val expected = '''
		{
			"name": "people",
			"simple-types":[
				{
					"kind":"string",
					"name":"default-type",
					"pattern":"^[\\p{Alpha}]+$",
					"min-length":1,
					"max-length":100
				}
			],
			"class-types":[
				{
					"name":"person",
					"properties":[
						{
							"name":"first-name",
							"type-ref":"default-type"
						},
						{
							"name":"last-name",
							"type-ref":"default-type"
						}]
				}
			],
			"responses":[],
			"path-scopes":[]
		}'''.toString

		val actual = fsa.textFiles.get(schemaFile).toString

		assertJsonEquals(expected, actual)
	}

	@Test
	def void generateClassTypeSpecifyDefaultType() {
		val spec = parseHelper.parse('''
			specification people {
				type default-type : string ^abc$ length [3..3]

				class person {
					first-name

					last-name
				}
			}
		''')
		assertNotNull(spec)

		val fsa = new InMemoryFileSystemAccess()
		generator.doGenerate(spec.eResource, fsa, null)

		println(fsa.textFiles)
		assertEquals(1, fsa.textFiles.size)
		assertTrue(fsa.textFiles.containsKey(schemaFile))

		val expected = '''
		{
			"name": "people",
			"simple-types":[
				{
					"kind":"string",
					"name":"default-type",
					"pattern":"^abc$",
					"min-length":3,
					"max-length":3
				}
			],
			"class-types":[
				{
					"name":"person",
					"properties":[
						{
							"name":"first-name",
							"type-ref":"default-type"
						},
						{
							"name":"last-name",
							"type-ref":"default-type"
						}
					]
				}
			],
			"responses":[],
			"path-scopes":[]
		}'''.toString

		val actual = fsa.textFiles.get(schemaFile).toString

		assertJsonEquals(expected, actual)
	}

	@Test
	def void generateClassTypeRestrictedProperties() {
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

		val fsa = new InMemoryFileSystemAccess()
		generator.doGenerate(spec.eResource, fsa, null)

		println(fsa.textFiles)
		assertEquals(1, fsa.textFiles.size)
		assertTrue(fsa.textFiles.containsKey(schemaFile))

		val expected = '''
		{
			"name": "people",
			"simple-types":[
				{
					"name":"name",
					"kind":"string",
					"pattern":"^[\\p{Alpha}\\']+$",
					"min-length":1,
					"max-length":100
				}
			],
			"class-types":[
				{
					"name":"person",
					"properties":[
						{
							"name":"first-name",
							"type-ref":"name"
						},
						{
							"name":"last-name",
							"type-ref":"name"
						}
					]
				}
			],
			"responses":[],
			"path-scopes":[]
		}'''.toString

		val actual = fsa.textFiles.get(schemaFile).toString

		assertJsonEquals(expected, actual)
	}

	@Test
	def void generateResponse() {
		val spec = parseHelper.parse('''
			specification people {
				class person {}

				response get-person-success : ok person
			}
		''')
		assertNotNull(spec)

		val fsa = new InMemoryFileSystemAccess()
		generator.doGenerate(spec.eResource, fsa, null)

		println(fsa.textFiles)
		assertEquals(1, fsa.textFiles.size)
		assertTrue(fsa.textFiles.containsKey(schemaFile))

		val expected = '''
		{
			"name": "people",
			"simple-types":[],
			"class-types":[
				{
					"name":"person",
					"properties":[]
				}
			],
			"responses":[
				{
					"name":"get-person-success",
					"status":200,
					"body-type-ref":"person"
				}
			],
			"path-scopes":[]
		}'''.toString

		val actual = fsa.textFiles.get(schemaFile).toString

		assertJsonEquals(expected, actual)
	}

	@Test
	def void generatePathScope() {
		val spec = parseHelper.parse('''
			specification people {
				path /person/{id} : person-ws {

				}
			}
		''')
		assertNotNull(spec)

		val fsa = new InMemoryFileSystemAccess()
		generator.doGenerate(spec.eResource, fsa, null)

		println(fsa.textFiles)
		assertEquals(1, fsa.textFiles.size)
		assertTrue(fsa.textFiles.containsKey(schemaFile))

		val expected = '''
		{
			"name": "people",
			"simple-types":[
				{
					"name":"default-type",
					"kind":"string",
					"pattern":"^[\\p{Alpha}]+$",
					"min-length":1,
					"max-length":100
				}
			],
			"class-types":[],
			"responses":[],
			"path-scopes":[
				{
					"name":"person-ws",
					"path":[
						{
							"kind":"static",
							"value":"person"
						},
						{
							"kind":"path-param",
							"name":"id",
							"type-ref":"default-type"
						}
					],
					"mappings":[]
				}
			]
		}'''.toString

		val actual = fsa.textFiles.get(schemaFile).toString

		assertJsonEquals(expected, actual)
	}

	def void generatePathScopeRestrictedId() {
		val spec = parseHelper.parse('''
			specification people {
				type uuid : string ^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$ length [36..36]

				path /person/{id : uuid} : person-ws {

				}
			}
		''')
		assertNotNull(spec)

		val fsa = new InMemoryFileSystemAccess()
		generator.doGenerate(spec.eResource, fsa, null)

		println(fsa.textFiles)
		assertEquals(1, fsa.textFiles.size)
		assertTrue(fsa.textFiles.containsKey(schemaFile))

		val expected = '''
		{
			"name": "people",
			"simple-types": [
				{
					"name": "name",
					"kind": "string",
					"pattern": "^[\\p{Alpha}\\']+$",
					"min-length": 1,
					"max-length": 100
				}
			],
			"class-types":[],
			"responses":[],
			"path-scopes":[]
		}'''.toString

		val actual = fsa.textFiles.get(schemaFile).toString

		assertJsonEquals(expected, actual)
	}

	@Test
	def void generateGet() {
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

		val fsa = new InMemoryFileSystemAccess()
		generator.doGenerate(spec.eResource, fsa, null)

		println(fsa.textFiles)
		assertEquals(1, fsa.textFiles.size)
		assertTrue(fsa.textFiles.containsKey(schemaFile))

		val expected = '''
		{
			"name": "people",
			"simple-types":[
				{
					"name":"default-type",
					"kind":"string",
					"pattern":"^[\\p{Alpha}]+$",
					"min-length":1,
					"max-length":100
				}
			],
			"class-types":[
				{
					"name":"person",
					"properties":[]
				}
			],
			"responses":[
				{
					"name":"get-person-success",
					"status":200,
					"body-type-ref":"person"
				}
			],
			"path-scopes":[
				{
					"name":"person-ws",
					"path":[
						{
							"kind":"static",
							"value":"person"
						},
						{
							"kind":"path-param",
							"name":"id",
							"type-ref":"default-type"
						}
					],
					"mappings":[
						{
							"kind":"http-method",
							"method":"GET",
							"name":"get-person",
							"parameters":[],
							"response-ref":"get-person-success"
						}
					]
				}
			]
		}'''.toString

		val actual = fsa.textFiles.get(schemaFile).toString

		assertJsonEquals(expected, actual)
	}

	@Test
	def void generateGetWithParam() {
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

		val fsa = new InMemoryFileSystemAccess()
		generator.doGenerate(spec.eResource, fsa, null)

		println(fsa.textFiles)
		assertEquals(1, fsa.textFiles.size)
		assertTrue(fsa.textFiles.containsKey(schemaFile))

		val expected = '''
		{
			"name": "people",
			"simple-types":[
				{
					"name":"default-type",
					"kind":"string",
					"pattern":"^[\\p{Alpha}]+$",
					"min-length":1,
					"max-length":100
				}
			],
			"class-types":[
				{
					"name":"person",
					"properties":[]
				}
			],
			"responses":[
				{
					"name":"get-person-success",
					"status":200,
					"body-type-ref":"person"
				}
			],
			"path-scopes":[
				{
					"name":"person-ws",
					"path":[
						{
							"kind":"static",
							"value":"person"
						},
						{
							"kind":"path-param",
							"name":"id",
							"type-ref":"default-type"
						}
					],
					"mappings":[
						{
							"kind":"http-method",
							"method":"GET",
							"name":"get-person",
							"parameters":[
								{
									"kind":"path-param-ref",
									"value-ref":"id"
								}
							],
							"response-ref":"get-person-success"
						}
					]
				}
			]
		}'''.toString

		val actual = fsa.textFiles.get(schemaFile).toString

		assertJsonEquals(expected, actual)
	}

	@Test
	def void generatePutWithParams() {
		val spec = parseHelper.parse('''
			specification people {
				class person {}

				response update-person-success : ok person

				path /person/{id} : person-ws {
					put -> update-person(/id, *person) : update-person-success
				}
			}
		''')
		assertNotNull(spec)

		val fsa = new InMemoryFileSystemAccess()
		generator.doGenerate(spec.eResource, fsa, null)

		println(fsa.textFiles)
		assertEquals(1, fsa.textFiles.size)
		assertTrue(fsa.textFiles.containsKey(schemaFile))

		val expected = '''
		{
			"name": "people",
			"simple-types":[
				{
					"name":"default-type",
					"kind":"string",
					"pattern":"^[\\p{Alpha}]+$",
					"min-length":1,
					"max-length":100
				}
			],
			"class-types":[
				{
					"name":"person",
					"properties":[]
				}
			],
			"responses":[
				{
					"name":"update-person-success",
					"status":200,
					"body-type-ref":"person"
				}
			],
			"path-scopes":[
				{
					"name":"person-ws",
					"path":[
						{
							"kind":"static",
							"value":"person"
						},
						{
							"kind":"path-param",
							"name":"id",
							"type-ref":"default-type"
						}
					],
					"mappings":[
						{
							"kind":"http-method",
							"method":"PUT",
							"name":"update-person",
							"parameters":[
								{
									"kind":"path-param-ref",
									"value-ref":"id"
								},
								{
									"kind":"body-param-ref",
									"type-ref":"person"
								}
							],
							"response-ref":"update-person-success"
						}
					]
				}
			]
		}'''.toString

		val actual = fsa.textFiles.get(schemaFile).toString

		assertJsonEquals(expected, actual)
	}

}
