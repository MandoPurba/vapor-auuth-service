// ModelExtensions.swift
// Typed accessors untuk field-field yang disimpan sebagai String di DB
// tapi ingin diakses sebagai enum di application code.

import Foundation

// MARK: - Session

extension Session {
    var authMethodEnum: AuthMethod? {
        AuthMethod(rawValue: authMethod)
    }
}

// MARK: - UserDevice

extension UserDevice {
    var platformEnum: Platform? {
        Platform(rawValue: platform)
    }

    var deviceTypeEnum: DeviceType? {
        DeviceType(rawValue: deviceType)
    }
}

// MARK: - MfaMethod

extension MfaMethod {
    var methodTypeEnum: MethodType? {
        MethodType(rawValue: methodType)
    }
}

// MARK: - BiometricCredential

extension BiometricCredential {
    var attestationTypeEnum: AttestationType? {
        guard let attestationType else { return nil }
        return AttestationType(rawValue: attestationType)
    }

    var transportsEnum: [Transport]? {
        transports?.compactMap { Transport(rawValue: $0) }
    }
}

// MARK: - AuditLog

extension AuditLog {
    var actionEnum: Action? {
        Action(rawValue: action)
    }

    var resultEnum: Result? {
        Result(rawValue: result)
    }
}