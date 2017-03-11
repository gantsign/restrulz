/*
 * Copyright 2016-2017 GantSign Ltd. All Rights Reserved.
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

	val schemaFile = IFileSystemAccess::DEFAULT_OUTPUT + "people.rrd.json"

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
			"title": "",
			"description": "",
			"version": "",
			"simple-types": [],
			"class-types":[],
			"responses":[],
			"path-scopes":[]
		}'''.toString

		val actual = fsa.textFiles.get(schemaFile).toString

		assertJsonEquals(expected, actual)
	}

	@Test
	def void generateSpecificationWithDoc() {
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

		val fsa = new InMemoryFileSystemAccess()
		generator.doGenerate(spec.eResource, fsa, null)

		println(fsa.textFiles)
		assertEquals(1, fsa.textFiles.size)
		assertTrue(fsa.textFiles.containsKey(schemaFile))

		val expected = '''
		{
			"name": "people",
			"title": "test1",
			"description": "test2\na\n\tb",
			"version": "test3",
			"simple-types": [],
			"class-types":[],
			"responses":[],
			"path-scopes":[]
		}'''.toString

		val actual = fsa.textFiles.get(schemaFile).toString

		assertJsonEquals(expected, actual)
	}

	@Test
	def void generateSpecificationWithDocWrap() {
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

		val fsa = new InMemoryFileSystemAccess()
		generator.doGenerate(spec.eResource, fsa, null)

		println(fsa.textFiles)
		assertEquals(1, fsa.textFiles.size)
		assertTrue(fsa.textFiles.containsKey(schemaFile))

		val expected = '''
		{
			"name": "people",
			"title": "test1",
			"description": "\ttest2\na\n\tb",
			"version": "test3",
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
			"title": "",
			"description": "",
			"version": "",
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
	def void generateIntegerType() {
		val spec = parseHelper.parse('''
			specification people {
				type age : int [0..150]
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
			"title": "",
			"description": "",
			"version": "",
			"simple-types": [
				{
					"name": "age",
					"kind": "integer",
					"minimum": 0,
					"maximum": 150
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
			"title": "",
			"description": "",
			"version": "",
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
							"type-ref":"default-type",
							"array":false
						},
						{
							"name":"last-name",
							"type-ref":"default-type",
							"array":false
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
			"title": "",
			"description": "",
			"version": "",
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
							"type-ref":"default-type",
							"array":false
						},
						{
							"name":"last-name",
							"type-ref":"default-type",
							"array":false
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
			"title": "",
			"description": "",
			"version": "",
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
							"type-ref":"name",
							"allow-empty":false,
							"array":false
						},
						{
							"name":"last-name",
							"type-ref":"name",
							"allow-empty":false,
							"array":false
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
	def void generateClassTypeWithBoolean() {
		val spec = parseHelper.parse('''
			specification people {
				class person {
					employed : boolean
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
			"title": "",
			"description": "",
			"version": "",
			"simple-types":[],
			"class-types":[
				{
					"name":"person",
					"properties":[
						{
							"name":"employed",
							"type-ref":"boolean",
							"allow-null":false,
							"array":false
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
	def void generateClassTypeRestrictedOptionalProperties() {
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

		val fsa = new InMemoryFileSystemAccess()
		generator.doGenerate(spec.eResource, fsa, null)

		println(fsa.textFiles)
		assertEquals(1, fsa.textFiles.size)
		assertTrue(fsa.textFiles.containsKey(schemaFile))

		val expected = '''
		{
			"name": "people",
			"title": "",
			"description": "",
			"version": "",
			"simple-types":[
				{
					"name":"name",
					"kind":"string",
					"pattern":"^[\\p{Alpha}\\']+$",
					"min-length":1,
					"max-length":100
				},
				{
					"name":"age",
					"kind":"integer",
					"minimum":0,
					"maximum":150
				}
			],
			"class-types":[
				{
					"name":"address",
					"properties":[]
				},
				{
					"name":"person",
					"properties":[
						{
							"name":"first-name",
							"type-ref":"name",
							"allow-empty":false,
							"array":false
						},
						{
							"name":"last-name",
							"type-ref":"name",
							"allow-empty":true,
							"array":false
						},
						{
							"name":"age",
							"type-ref":"age",
							"allow-null":true,
							"array":false
						},
						{
							"name":"address",
							"type-ref":"address",
							"allow-null":true,
							"array":false
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
	def void generateClassTypeArrayProperties() {
		val spec = parseHelper.parse('''
			specification people {
				class address {}

				class person {
					addresses: address[]
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
			"title": "",
			"description": "",
			"version": "",
			"simple-types":[],
			"class-types":[
				{
					"name":"address",
					"properties":[]
				},
				{
					"name":"person",
					"properties":[
						{
							"name":"addresses",
							"type-ref":"address",
							"array":true
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
			"title": "",
			"description": "",
			"version": "",
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
					"body-type-ref":"person",
					"array":false
				}
			],
			"path-scopes":[]
		}'''.toString

		val actual = fsa.textFiles.get(schemaFile).toString

		assertJsonEquals(expected, actual)
	}

	@Test
	def void generateResponseArray() {
		val spec = parseHelper.parse('''
			specification people {
				class person {}

				response get-person-success : ok person[]
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
			"title": "",
			"description": "",
			"version": "",
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
					"body-type-ref":"person",
					"array":true
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
			"title": "",
			"description": "",
			"version": "",
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

	@Test
	def void generatePathScopeRoot() {
		val spec = parseHelper.parse('''
			specification people {
				path / : person-ws {

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
			"title": "",
			"description": "",
			"version": "",
			"simple-types":[],
			"class-types":[],
			"responses":[],
			"path-scopes":[
				{
					"name":"person-ws",
					"path":[],
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
			"title": "",
			"description": "",
			"version": "",
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

	def void generateSubPathScope() {
		val spec = parseHelper.parse('''
			specification people {
				path /person : person-ws {
					path /details {

					}
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
			"title": "",
			"description": "",
			"version": "",
			"simple-types":[],
			"class-types":[],
			"responses":[],
			"path-scopes":[
				{
					"name": "person-ws",
					"path": [
						{
							"kind": "static",
							"value": "person"
						}
					],
					"mappings": [
						{
							"kind": "path",
							"path": [
								{
									"kind": "static",
									"value": "details"
								}
							],
							"mappings": []
						}
					]
				}
			]
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
			"title": "",
			"description": "",
			"version": "",
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
					"body-type-ref":"person",
					"array":false
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
							"response-refs":["get-person-success"]
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
					get -> get-person(id = /id) : get-person-success
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
			"title": "",
			"description": "",
			"version": "",
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
					"body-type-ref":"person",
					"array":false
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
									"name":"id",
									"kind":"path-param-ref",
									"value-ref":"id"
								}
							],
							"response-refs":["get-person-success"]
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
					put -> update-person(id = /id, person = *person) : update-person-success
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
			"title": "",
			"description": "",
			"version": "",
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
					"body-type-ref":"person",
					"array":false
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
									"name":"id",
									"kind":"path-param-ref",
									"value-ref":"id"
								},
								{
									"name":"person",
									"kind":"body-param-ref",
									"type-ref":"person"
								}
							],
							"response-refs":["update-person-success"]
						}
					]
				}
			]
		}'''.toString

		val actual = fsa.textFiles.get(schemaFile).toString

		assertJsonEquals(expected, actual)
	}

}
