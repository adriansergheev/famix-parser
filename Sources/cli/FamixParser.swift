//
//  
//
//  Created by Adrian Sergheev on 2021-04-27.
//

import Foundation

// MARK: - Parsing FAMIX

var famixStrExample = """
((FAMIX.Namespace (id: 1)
    (name 'aNamespace'))
  (FAMIX.Package (id: 201)
    (name 'aPackage'))
  (FAMIX.Package (id: 202)
    (name 'anotherPackage')
    (parentPackage (ref: 201)))
  (FAMIX.Package (id: 203)
    (name 'anotherPackage')
    (parentPackage (ref: 201)))
  (FAMIX.Class (id: 2)
    (name 'ClassA')
    (container (ref: 1))
    (parentPackage (ref: 201)))
  (FAMIX.Method
    (name 'methodA1')
    (signature 'methodA1()')
    (parentType (ref: 2))
    (LOC 2))
  (FAMIX.Method
    (name 'methodA2')
    (signature 'methodA2()')
    (parentType (ref: 3))
    (LOC 3))
  (FAMIX.Method
    (name 'methodA3')
    (signature 'methodA3()')
    (parentType (ref: 4))
    (LOC 4))
  (FAMIX.Attribute
    (name 'attributeA1')
    (parentType (ref: 2)))
  (FAMIX.Class (id: 3)
    (name 'ClassB')
    (container (ref: 1))
    (parentPackage (ref: 202)))
  (FAMIX.Inheritance
    (subclass (ref: 3))
    (superclass (ref: 2))))
"""

// MARK: - FAMIX Entity

enum FamixEntity {
    case namespace(name: String, id: Int)
    case package(name: String, id: Int, parentPackage: Int?)
    case `class`(name: String, id: Int, container: Int, parentPackage: Int)
    case method(name: String, signature: String, parentType: Int, loc: Int)
    case attribute(name: String, parentType: Int)
    case inheritance(subclass: Int, superClass: Int)
}

extension FamixEntity {
    var name: String {
        switch self {
        case .namespace:
            return "Namespace"
        case .package:
            return "Package"
        case .class:
            return "Class"
        case .method:
            return "Method"
        case .attribute:
            return "Attribute"
        case .inheritance:
            return "Inheritance"
        }
    }
}

extension FamixEntity: CustomDebugStringConvertible {
    var debugDescription: String {
        switch self {
        case .namespace(name: let name, id: let id):
            return "FAMIX.namespace, name: \(name), id: \(id)"
        case .package(name: let name, id: let id, parentPackage: let parentPackage):
            return "FAMIX.package, name: \(name), id: \(id), parentPackageID: \(String(describing: parentPackage))"
        case .class(name: let name, id: let id, container: let containerID, parentPackage: let parentPackageID):
            return "FAMIX.class, name: \(name), id: \(id), container: \(containerID), parentPackage: \(parentPackageID)"
        case .method(name: let name, signature: let signature, parentType: let parentType, loc: let loc):
            return "FAMIX.method, name: \(name), signature: \(signature), parentType: \(parentType), LOC: \(loc)"
        case .attribute(name: let name, parentType: let parentID):
            return "FAMIX.attribute, name: \(name), parentID: \(parentID)"
        case .inheritance(subclass: let subclass, superClass: let superclass):
            return "FAMIX.inheritance, subclassID: \(subclass), superclassID: \(superclass)"
        }
    }
}

// MARK: - Shared Parsers

let zeroOrMoreSpaces = Parser.prefix(while: { $0 == " "})
    .map { _ in Void() }

let newLineAndSpaceSeparator = zip(.prefix("\n"), zeroOrMoreSpaces)
    .map { _, _ in Void() }

// MARK: - Shared FAMIX entity attributes

let nameFieldParser = zip(
    zeroOrMoreSpaces,
    .prefix("(name '"),
    .prefix(while: { $0 != "'" }),
    .prefix("')")
).map { _, _, name, _ in name }

let packageFieldParser = Parser
    .skip(.prefix("(parentPackage (ref: "))
    .take(.int)
    .skip(.prefix(through: "))"))
    .map { _, id in id }

// MARK: - FAMIX.Namespace

let nameSpaceEntityIdentifier = zip(
    .prefix("(FAMIX.Namespace (id: "),
    .int,
    .prefix(through: ")")
).map { _, id, _ in id }

let famixEntityNamespace = zip(
    zip(nameSpaceEntityIdentifier, newLineAndSpaceSeparator)
        .map { id, _ in id },
    nameFieldParser,
    .prefix(")")
).map { id, name, _  in
    FamixEntity.namespace(name: String(name), id: id)
}

// MARK: - FAMIX.Package

let packageEntityIdentifier = Parser
    .skip(.prefix("(FAMIX.Package (id: "))
    .take(.int)
    .skip(.prefix(through: ")"))
    .map { _, id in id }

let famixEntityPackage = zip(
    packageEntityIdentifier,
    newLineAndSpaceSeparator,
    nameFieldParser,
    .optional(zip(newLineAndSpaceSeparator, packageFieldParser)),
    .prefix(")")
).map { id, _, name, parentId, _ in
    FamixEntity.package(name: String(name), id: id, parentPackage: parentId?.1)
}

// MARK: - FAMIX.Class

let classEntityIdentifier = Parser
    .skip(.prefix("(FAMIX.Class (id: "))
    .take(.int)
    .skip(.prefix(through: ")"))
    .map { _, id in id }

let classContainerIdentifier = Parser
    .skip(.prefix("(container (ref: "))
    .take(.int)
    .skip(.prefix(through: "))"))

let famixEntityClass = zip(
    zip(classEntityIdentifier, newLineAndSpaceSeparator)
        .map { id, _ in id },
    zip(nameFieldParser, newLineAndSpaceSeparator)
        .map { name, _ in name },
    zip(classContainerIdentifier, newLineAndSpaceSeparator)
        .map { containerId, _ in containerId.1 },
    zip(packageFieldParser, .prefix(")"))
        .map { packageId, _ in packageId}
).map { classId, name, containerId, packageId in
    FamixEntity.class(name: String(name),
                      id: classId,
                      container: containerId,
                      parentPackage: packageId)
}

// MARK: - FAMIX.Method

let methodEntityIdentifier = Parser
    .skip(.prefix("(FAMIX.Method"))

let methodSignatureIdentifier = Parser
    .skip(.prefix("(signature '"))
    .take(.prefix(while: { $0 != "'" }))
    .skip(.prefix(through: ")"))

let methodParentTypeIdentifier = Parser
    .skip(.prefix("(parentType (ref: "))
    .take(.int)
    .skip(.prefix(through: "))"))

let methodLocIdentifier = Parser
    .skip(.prefix("(LOC "))
    .take(.int)
    .skip(.prefix(through: "))"))

let famixEntityMethod = zip(
    zip(methodEntityIdentifier, newLineAndSpaceSeparator)
        .map { _, _ in Void() },
    zip(nameFieldParser, newLineAndSpaceSeparator)
        .map { name, _ in name },
    zip(methodSignatureIdentifier, newLineAndSpaceSeparator)
        .map { tuple, _ in tuple.1 },
    zip(methodParentTypeIdentifier, newLineAndSpaceSeparator)
        .map { tuple, _ in tuple.1 },
    methodLocIdentifier.map { tuple in tuple.1 }
).map { _, name, signature, parentTypeId, locId in
    FamixEntity.method(name: String(name),
                       signature: String(signature),
                       parentType: parentTypeId,
                       loc: locId)
}

// MARK: - FAMIX.Attribute

let attributeEntityIdentifier = Parser
    .skip(.prefix("(FAMIX.Attribute"))

let famixEntityAttribute = zip(
    zip(attributeEntityIdentifier, newLineAndSpaceSeparator)
        .map { _ in Void() },
    zip(nameFieldParser, newLineAndSpaceSeparator)
        .map { name, _ in name },
    zip(methodParentTypeIdentifier, .prefix(")"))
        .map { tuple, _ in tuple.1 }
).map { _, name, id in
    FamixEntity.attribute(name: String(name), parentType: id)
}

// MARK: - FAMIX.Inheritance

let inheritanceEntityIdentifier = Parser
    .skip(.prefix("(FAMIX.Inheritance"))

let inheritanceSubclassIdentifier = Parser
    .skip(.prefix("(subclass (ref: "))
    .take(.int)
    .skip(.prefix(through: "))"))
    .map { _, id in id }

let inheritanceSuperclassIdentifier = Parser
    .skip(.prefix("(superclass (ref: "))
    .take(.int)
    .skip(.prefix(through: "))"))
    .map { _, id in id }

let famixEntityInheritance = zip(
    zip(inheritanceEntityIdentifier, newLineAndSpaceSeparator)
        .map { _ in Void() },
    zip(inheritanceSubclassIdentifier, newLineAndSpaceSeparator)
        .map { id, _ in id },
    zip(inheritanceSuperclassIdentifier, .prefix(")"))
        .map { id, _ in id }
).map { _, subclassId, superclassId in
    FamixEntity.inheritance(subclass: subclassId, superClass: superclassId)
}

// MARK: - FAMIX Parser
let famixEntity = Parser.oneOf([
    famixEntityNamespace,
    famixEntityPackage,
    famixEntityClass,
    famixEntityMethod,
    famixEntityAttribute,
    famixEntityInheritance
])

let famixParser = Parser
    .skip(.prefix("("))
    .take(famixEntity.zeroOrMore(separatedBy: newLineAndSpaceSeparator))
    .skip(.prefix(")"))
