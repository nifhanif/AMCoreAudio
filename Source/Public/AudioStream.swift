//
//  AudioStream.swift
//  AMCoreAudio
//
//  Created by Ruben Nine on 13/04/16.
//  Copyright © 2016 9Labs. All rights reserved.
//

import CoreAudio.AudioHardwareBase
import Foundation

/// `AudioStream`
///
/// This class represents an audio stream belonging to an audio object.
public final class AudioStream: AudioObject {
    // MARK: - Public Properties

    /// This audio stream's identifier.
    ///
    /// - Returns: An `AudioObjectID`.
    public var id: AudioObjectID {
        return objectID
    }

    /// Returns whether this audio stream is enabled and doing I/O.
    ///
    /// - Returns: `true` when enabled, `false` otherwise.
    public var active: Bool {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioStreamPropertyIsActive,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMaster
        )

        guard AudioObjectHasProperty(self.id, &address) else { return false }
        var active: UInt32 = 0
        guard noErr == self.getPropertyData(address, andValue: &active) else { return false }

        return active == 1
    }

    /// Specifies the first element in the owning device that corresponds to the element one of this stream.
    ///
    /// - Returns: *(optional)* A `UInt32`.
    public var startingChannel: UInt32? {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioStreamPropertyStartingChannel,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMaster
        )

        guard AudioObjectHasProperty(self.id, &address) else { return nil }
        var startingChannel: UInt32 = 0
        guard noErr == self.getPropertyData(address, andValue: &startingChannel) else { return nil }

        return startingChannel
    }

    /// Describes the general kind of functionality attached to this stream.
    ///
    /// - Return: A `TerminalType`.
    public var terminalType: TerminalType {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioStreamPropertyTerminalType,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMaster
        )

        guard AudioObjectHasProperty(id, &address) else { return .unknown }
        var terminalType: UInt32 = 0
        guard noErr == getPropertyData(address, andValue: &terminalType) else { return .unknown }

        switch terminalType {
        case kAudioStreamTerminalTypeLine:
            return .line
        case kAudioStreamTerminalTypeDigitalAudioInterface:
            return .digitalAudioInterface
        case kAudioStreamTerminalTypeSpeaker:
            return .speaker
        case kAudioStreamTerminalTypeHeadphones:
            return .headphones
        case kAudioStreamTerminalTypeLFESpeaker:
            return .lfeSpeaker
        case kAudioStreamTerminalTypeReceiverSpeaker:
            return .receiverSpeaker
        case kAudioStreamTerminalTypeMicrophone:
            return .microphone
        case kAudioStreamTerminalTypeHeadsetMicrophone:
            return .headsetMicrophone
        case kAudioStreamTerminalTypeReceiverMicrophone:
            return .receiverMicrophone
        case kAudioStreamTerminalTypeTTY:
            return .tty
        case kAudioStreamTerminalTypeHDMI:
            return .hdmi
        case kAudioStreamTerminalTypeDisplayPort:
            return .displayPort
        case kAudioStreamTerminalTypeUnknown:
            fallthrough
        default:
            return .unknown
        }
    }

    /// The latency in frames for this stream.
    ///
    /// Note that the owning `AudioDevice` may have additional latency so it should be
    /// queried as well. If both the device and the stream say they have latency,
    /// then the total latency for the stream is the device latency summed with the
    /// stream latency.
    ///
    /// - Returns: *(optional)* A `UInt32` value with the latency in frames.
    public var latency: UInt32? {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioStreamPropertyLatency,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMaster
        )

        guard AudioObjectHasProperty(id, &address) else { return nil }
        var latency: UInt32 = 0
        guard noErr == getPropertyData(address, andValue: &latency) else { return nil }

        return latency
    }

    /// The audio stream's direction.
    ///
    /// For output streams, and to continue using the same `Direction` concept used by `AudioDevice`,
    /// this will be `Direction.Playback`, likewise, for input streams, `Direction.Recording` will be returned.
    ///
    /// - Returns: *(optional)* A `Direction`.
    public var direction: Direction? {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioStreamPropertyDirection,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMaster
        )

        guard AudioObjectHasProperty(id, &address) else { return nil }
        var direction: UInt32 = 0
        guard noErr == getPropertyData(address, andValue: &direction) else { return nil }

        switch direction {
        case 0:
            return .playback
        case 1:
            return .recording
        default:
            return nil
        }
    }

    /// An `AudioStreamBasicDescription` that describes the current data format for this audio stream.
    ///
    /// - SeeAlso: `virtualFormat`
    ///
    /// - Returns: *(optional)* An `AudioStreamBasicDescription`.
    public var physicalFormat: AudioStreamBasicDescription? {
        get {
            var asbd = AudioStreamBasicDescription()
            guard noErr == getStreamPropertyData(kAudioStreamPropertyPhysicalFormat, andValue: &asbd) else { return nil }

            return asbd
        }

        set {
            var asbd = newValue

            if noErr == setStreamPropertyData(kAudioStreamPropertyPhysicalFormat, andValue: &asbd) {
                log("Error setting physicalFormat to \(String(describing: newValue))")
            }
        }
    }

    /// An `AudioStreamBasicDescription` that describes the current virtual data format for this audio stream.
    ///
    /// - SeeAlso: `physicalFormat`
    ///
    /// - Returns: *(optional)* An `AudioStreamBasicDescription`.
    public var virtualFormat: AudioStreamBasicDescription? {
        get {
            var asbd = AudioStreamBasicDescription()
            guard noErr == getStreamPropertyData(kAudioStreamPropertyVirtualFormat, andValue: &asbd) else { return nil }

            return asbd
        }

        set {
            var asbd = newValue

            if noErr == setStreamPropertyData(kAudioStreamPropertyVirtualFormat, andValue: &asbd) {
                log("Error setting virtualFormat to \(String(describing: newValue))")
            }
        }
    }

    /// All the available physical formats for this audio stream.
    ///
    /// - SeeAlso: `availableVirtualFormats`
    ///
    /// - Returns: *(optional)* An array of `AudioStreamRangedDescription` structs.
    public lazy var availablePhysicalFormats: [AudioStreamRangedDescription]? = {
        guard let direction = self.direction else { return nil }

        var address = AudioObjectPropertyAddress(
            mSelector: kAudioStreamPropertyAvailablePhysicalFormats,
            mScope: scope(direction: direction),
            mElement: kAudioObjectPropertyElementMaster
        )

        guard AudioObjectHasProperty(id, &address) else { return nil }
        var asrd = [AudioStreamRangedDescription]()
        guard noErr == getPropertyDataArray(address, value: &asrd, andDefaultValue: AudioStreamRangedDescription()) else {
            return nil
        }

        return asrd
    }()

    /// All the available virtual formats for this audio stream.
    ///
    /// - SeeAlso: `availablePhysicalFormats`
    ///
    /// - Returns: *(optional)* An array of `AudioStreamRangedDescription` structs.
    public lazy var availableVirtualFormats: [AudioStreamRangedDescription]? = {
        guard let direction = self.direction else { return nil }

        var address = AudioObjectPropertyAddress(
            mSelector: kAudioStreamPropertyAvailableVirtualFormats,
            mScope: scope(direction: direction),
            mElement: kAudioObjectPropertyElementMaster
        )

        guard AudioObjectHasProperty(id, &address) else { return nil }
        var asrd = [AudioStreamRangedDescription]()
        guard noErr == getPropertyDataArray(address, value: &asrd, andDefaultValue: AudioStreamRangedDescription()) else {
            return nil
        }

        return asrd
    }()

    // MARK: - Private Properties

    private var isRegisteredForNotifications = false

    private lazy var propertyListenerBlock: AudioObjectPropertyListenerBlock = { (_, inAddresses) -> Void in
        let address = inAddresses.pointee
        let direction = AMCoreAudio.direction(to: address.mScope)
        let notificationCenter = NotificationCenter.defaultCenter

        switch address.mSelector {
        case kAudioStreamPropertyIsActive:
            notificationCenter.publish(AudioStreamEvent.isActiveDidChange(audioStream: self))
        case kAudioStreamPropertyPhysicalFormat:
            notificationCenter.publish(AudioStreamEvent.physicalFormatDidChange(audioStream: self))
        default:
            break
        }
    }

    // MARK: - Public Functions

    /// Returns an `AudioStream` by providing a valid audio stream identifier.
    ///
    /// - Note: If identifier is not valid, `nil` will be returned.
    public static func lookup(by id: AudioObjectID) -> AudioStream? {
        var instance = AudioObjectPool.instancePool.object(forKey: NSNumber(value: UInt(id))) as? AudioStream

        if instance == nil {
            instance = AudioStream(id: id)
        }

        return instance
    }
  
  static public var register = false

    /// Initializes an `AudioStream` by providing a valid `AudioObjectID` referencing an existing audio stream.
    private init?(id: AudioObjectID) {
        super.init(objectID: id)

        guard owningObject != nil else { return nil }

      if AudioStream.register {
        registerForNotifications()
      }
        AudioObjectPool.instancePool.setObject(self, forKey: NSNumber(value: UInt(objectID)))
    }

    deinit {
        unregisterForNotifications()
        AudioObjectPool.instancePool.removeObject(forKey: NSNumber(value: UInt(objectID)))
    }

    /// All the available physical formats for this audio stream matching the current physical format's sample rate.
    ///
    /// - Note: By default, both mixable and non-mixable streams are returned, however,  non-mixable
    /// streams can be filtered out by setting `includeNonMixable` to `false`.
    ///
    /// - Parameter includeNonMixable: Whether to include non-mixable streams in the returned array. Defaults to `true`.
    ///
    /// - SeeAlso: `availableVirtualFormatsMatchingCurrentNominalSampleRate(_:)`
    ///
    /// - Returns: *(optional)* An array of `AudioStreamBasicDescription` structs.
    public final func availablePhysicalFormatsMatchingCurrentNominalSampleRate(_ includeNonMixable: Bool = true) -> [AudioStreamBasicDescription]? {
        guard let physicalFormats = availablePhysicalFormats, let physicalFormat = physicalFormat else { return nil }

        var filteredFormats = physicalFormats.filter { (format) -> Bool in
            format.mSampleRateRange.mMinimum >= physicalFormat.mSampleRate &&
                format.mSampleRateRange.mMaximum <= physicalFormat.mSampleRate
        }.map { $0.mFormat }

        if !includeNonMixable {
            filteredFormats = filteredFormats.filter { $0.mFormatFlags & kAudioFormatFlagIsNonMixable == 0 }
        }

        return filteredFormats
    }

    /// All the available virtual formats for this audio stream matching the current virtual format's sample rate.
    ///
    /// - Note: By default, both mixable and non-mixable streams are returned, however,  non-mixable
    /// streams can be filtered out by setting `includeNonMixable` to `false`.
    ///
    /// - Parameter includeNonMixable: Whether to include non-mixable streams in the returned array. Defaults to `true`.
    ///
    /// - SeeAlso: `availablePhysicalFormatsMatchingCurrentNominalSampleRate(_:)`
    ///
    /// - Returns: *(optional)* An array of `AudioStreamBasicDescription` structs.
    public final func availableVirtualFormatsMatchingCurrentNominalSampleRate(_ includeNonMixable: Bool = true) -> [AudioStreamBasicDescription]? {
        guard let virtualFormats = availableVirtualFormats, let virtualFormat = virtualFormat else { return nil }

        var filteredFormats = virtualFormats.filter { (format) -> Bool in
            format.mSampleRateRange.mMinimum >= virtualFormat.mSampleRate &&
                format.mSampleRateRange.mMaximum <= virtualFormat.mSampleRate
        }.map { $0.mFormat }

        if !includeNonMixable {
            filteredFormats = filteredFormats.filter { $0.mFormatFlags & kAudioFormatFlagIsNonMixable == 0 }
        }

        return filteredFormats
    }

    // MARK: - Private Functions

    /// This is an specialized version of `getPropertyData` that only requires passing an `AudioObjectPropertySelector`
    /// instead of an `AudioObjectPropertyAddress`. The scope is computed from the stream's `Direction`, and the element
    /// is assumed to be `kAudioObjectPropertyElementMaster`.
    ///
    /// Additionally, the property address is validated before calling `getPropertyData`.
    ///
    /// - Parameter selector: The `AudioObjectPropertySelector` that points to the property we want to get.
    /// - Parameter value: The value that will be returned.
    ///
    /// - Returns: An `OSStatus` with `noErr` on success, or an error code other than `noErr` when it fails.
    private func getStreamPropertyData<T>(_ selector: AudioObjectPropertySelector, andValue value: inout T) -> OSStatus? {
        guard let direction = direction else { return nil }

        var address = AudioObjectPropertyAddress(
            mSelector: selector,
            mScope: scope(direction: direction),
            mElement: kAudioObjectPropertyElementMaster
        )

        guard AudioObjectHasProperty(id, &address) else { return nil }

        return getPropertyData(address, andValue: &value)
    }

    /// This is an specialized version of `setPropertyData` that only requires passing an `AudioObjectPropertySelector`
    /// instead of an `AudioObjectPropertyAddress`. The scope is computed from the stream's `Direction`, and the element
    /// is assumed to be `kAudioObjectPropertyElementMaster`.
    ///
    /// Additionally, the property address is validated before calling `setPropertyData`.
    ///
    /// - Parameter selector: The `AudioObjectPropertySelector` that points to the property we want to set.
    /// - Parameter value: The new value we want to set.
    ///
    /// - Returns: An `OSStatus` with `noErr` on success, or an error code other than `noErr` when it fails.
    private func setStreamPropertyData<T>(_ selector: AudioObjectPropertySelector, andValue value: inout T) -> OSStatus? {
        guard let direction = direction else { return nil }

        var address = AudioObjectPropertyAddress(
            mSelector: selector,
            mScope: scope(direction: direction),
            mElement: kAudioObjectPropertyElementMaster
        )

        guard AudioObjectHasProperty(id, &address) else { return nil }

        return setPropertyData(address, andValue: &value)
    }

    // MARK: - Notification Book-keeping

    private func registerForNotifications() {
        if isRegisteredForNotifications {
            unregisterForNotifications()
        }

        var address = AudioObjectPropertyAddress(
            mSelector: kAudioObjectPropertySelectorWildcard,
            mScope: kAudioObjectPropertyScopeWildcard,
            mElement: kAudioObjectPropertyElementWildcard
        )

        let err = AudioObjectAddPropertyListenerBlock(id, &address, NotificationCenter.notificationsQueue, propertyListenerBlock)

        if noErr != err {
            log("Error on AudioObjectAddPropertyListenerBlock: \(err)")
        }

        isRegisteredForNotifications = noErr == err
    }

    private func unregisterForNotifications() {
        guard isRegisteredForNotifications else { return }

        var address = AudioObjectPropertyAddress(
            mSelector: kAudioObjectPropertySelectorWildcard,
            mScope: kAudioObjectPropertyScopeWildcard,
            mElement: kAudioObjectPropertyElementWildcard
        )

        let err = AudioObjectRemovePropertyListenerBlock(id, &address, NotificationCenter.notificationsQueue, propertyListenerBlock)

        if noErr != err {
            log("Error on AudioObjectRemovePropertyListenerBlock: \(err)")
        }

        isRegisteredForNotifications = noErr != err
    }
}

extension AudioStream: CustomStringConvertible {
    // MARK: - CustomStringConvertible Protocol

    /// Returns a `String` representation of self.
    public var description: String {
        return "\(name ?? "Stream \(id)") (\(id))"
    }
}
