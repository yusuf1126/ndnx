package com.parc.ccn.library.profiles;

import java.math.BigInteger;
import java.sql.Timestamp;

import com.parc.ccn.Library;
import com.parc.ccn.data.ContentName;
import com.parc.ccn.data.security.SignedInfo;
import com.parc.ccn.data.util.DataUtils;

/**
 * Versions, when present, occupy the penultimate component of the CCN name, 
 * not counting the digest component. They may be chosen based on time.
 * The first byte of the version component is 0xFD. The remaining bytes are a
 * big-endian binary number. If based on time they are expressed in units of
 * 2**(-12) seconds since the start of Unix time, using the minimum number of
 * bytes. The time portion will thus take 48 bits until quite a few centuries
 * from now (Sun, 20 Aug 4147 07:32:16 GMT). With 12 bits of precision, it allows 
 * for sub-millisecond resolution. The client generating the version stamp 
 * should try to avoid using a stamp earlier than (or the same as) any 
 * version of the file, to the extent that it knows about it. It should 
 * also avoid generating stamps that are unreasonably far in the future.
 */
public class VersioningProfile implements CCNProfile {

	public static final byte VERSION_MARKER = (byte)0xFD;
	public static final byte [] FIRST_VERSION_MARKER = new byte []{VERSION_MARKER};

	/**
	 * Add a version field to a ContentName.
	 * @return ContentName with any previous version field and sequence number removed and new version field added.
	 */
	public static ContentName versionName(ContentName name, long version) {
		// Need a minimum-bytes big-endian representation of version.
		ContentName baseName = name;
		if (isVersioned(name)) {
			baseName = versionRoot(name);
		}
		byte [] vcomp = null;
		if (0 == version) {
			vcomp = FIRST_VERSION_MARKER;
		} else {
			byte [] varr = BigInteger.valueOf(version).toByteArray();
			vcomp = new byte[varr.length + 1];
			vcomp[0] = VERSION_MARKER;
			System.arraycopy(varr, 0, vcomp, 1, varr.length);
		}
		return new ContentName(baseName, vcomp);
	}
	
	/**
	 * Converts a timestamp into a fixed point representation, with 12 bits in the fractional
	 * component, and adds this to the ContentName as a version field. The timestamp is rounded
	 * to the nearest value in the fixed point representation.
	 * <p>
	 * This allows versions to be recorded as a timestamp with a 1/4096 second accuracy.
	 * @see #versionName(ContentName, long)
	 */
	public static ContentName versionName(ContentName name, Timestamp version) {
		return versionName(name, DataUtils.timestampToBinaryTime12AsLong(version));
	}
	
	/**
	 * Add a version field based on the current time, accurate to 1/4096 second.
	 * @see #versionName(ContentName, Timestamp)
	 */
	public static ContentName versionName(ContentName name) {
		return versionName(name, SignedInfo.now());
	}
	
	/**
	 * Finds the last component that looks like a version in name.
	 * @param name
	 * @return the index of the last version component in the name, or -1 if there is no version
	 *					component in the name
	 */
	public static int findVersionComponent(ContentName name) {
		int i = name.count();
		for (;i >= 0; i--)
			if (isVersionComponent(name.component(i)))
				return i;
		return -1;
	}

	/**
	 * Checks to see if this name has a validly formatted version field.
	 */
	public static boolean isVersioned(ContentName name) {
		return findVersionComponent(name) != -1;
	}
	
	/**
	 * Check a name component to see if it is a valid version field
	 */
	public static boolean isVersionComponent(byte [] nameComponent) {
		return (null != nameComponent) && (0 != nameComponent.length) && 
			   (VERSION_MARKER == nameComponent[0]) && 
			   ((nameComponent.length == 1) || (nameComponent[1] != 0));
	}

	/**
	 * Take a name which has a version component
	 * and strips it and any following components if present.
	 * @throws VersionMissingException
	 */
	public static ContentName versionRoot(ContentName name) throws VersionMissingException {
		int offset = findVersionComponent(name);
		if (offset == -1)
			throw new VersionMissingException();
		return new ContentName(offset, name.components());
	}

	/**
	 * Does this name represent a version of the given parent?
	 * DKS TODO -- do we need a tighter definition? e.g. is this a data block of
	 * this version, versus metadata, etc...
	 * @param versionedName name with version to be checked.
	 * @param parent name without version field that will be checked against.
	 * Note - the parent name must contain all the name components up to but not including the version
	 * component in the versionedName.
	 * @return
	 */
	public static boolean isVersionOf(ContentName versionedName, ContentName parent) {
		int i = findVersionComponent(versionedName);
		
		// check version field is in right place (just after parent)
		// this also catches cases where there is no version field.
		if (i != parent.count())
			return false;
				
		return parent.isPrefixOf(versionedName);
	}
	
	/**
	 * Function to get the version field as a long.  Starts from the end and checks each name component for the version marker.
	 * @param name
	 * @return long
	 * @throws VersionMissingException
	 */
	public static long getVersionAsLong(ContentName name) throws VersionMissingException {
		int i = findVersionComponent(name);
		if (i == -1)
			throw new VersionMissingException();
		
		return getVersionComponentAsLong(name.component(i));
	}
	
	public static long getVersionComponentAsLong(byte [] versionComponent) {
		byte [] versionData = new byte[versionComponent.length - 1];
		System.arraycopy(versionComponent, 1, versionData, 0, versionComponent.length - 1);
		return new BigInteger(versionData).longValue();
	}

	public static Timestamp getVersionComponentAsTimestamp(byte [] versionComponent) {
		return versionLongToTimestamp(getVersionComponentAsLong(versionComponent));
	}

	/**
	 * Extract the version from this name as a Timestamp.
	 * @throws VersionMissingException 
	 */
	public static Timestamp getVersionAsTimestamp(ContentName name) throws VersionMissingException {
		long time = getVersionAsLong(name);
		return DataUtils.binaryTime12ToTimestamp(time);
	}
	
	public static Timestamp versionLongToTimestamp(long version) {
		return DataUtils.binaryTime12ToTimestamp(version);
	}
	/**
	 * Control whether versions start at 0 or 1.
	 * @return
	 */
	public static final int baseVersion() { return 0; }

	public static int compareVersions(
			Timestamp left,
			ContentName right) {
		if (!isVersioned(right)) {
			throw new IllegalArgumentException("Both names to compare must be versioned!");
		}
		try {
			return left.compareTo(getVersionAsTimestamp(right));
		} catch (VersionMissingException e) {
			throw new IllegalArgumentException("Name that isVersioned returns true for throws VersionMissingException!: " + right);
		}
	}
	
	/**
	 * This doesn't currently insist that left and right be versions of the same name,
	 * just that they both be versioned.
	 * @param left
	 * @param right
	 * @return
	 */
	public static int compareVersions(
			ContentName left,
			ContentName right) {
		try {
			return getVersionAsTimestamp(left).compareTo(getVersionAsTimestamp(right));
		} catch (VersionMissingException e) {
			throw new IllegalArgumentException("Both names to compare must be versioned!");
		}
	}

	public static boolean isLaterVersionOf(ContentName laterVersion, ContentName earlierVersion) {
		if (!versionRoot(laterVersion).equals(versionRoot(earlierVersion))) {
			return false; // not versions of the same thing
		}
		return (compareVersions(laterVersion, earlierVersion) > 0);
    }

	public static Timestamp getVersionAsTimestampIfVersioned(ContentName name) {
		try {
			if (!isVersioned(name))
				return null;
			return getVersionAsTimestamp(name);
		} catch (VersionMissingException e) {
			Library.logger().info("Unexpected: version missing exception when we tried to pull version from name with isVersioned=true, name: " + name + " message: " + e.getMessage());
			return null;
		}
	}
}
