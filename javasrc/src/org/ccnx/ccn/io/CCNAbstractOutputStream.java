/**
 * Part of the CCNx Java Library.
 *
 * Copyright (C) 2008, 2009 Palo Alto Research Center, Inc.
 *
 * This library is free software; you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License version 2.1
 * as published by the Free Software Foundation. 
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * Lesser General Public License for more details. You should have received
 * a copy of the GNU Lesser General Public License along with this library;
 * if not, write to the Free Software Foundation, Inc., 51 Franklin Street,
 * Fifth Floor, Boston, MA 02110-1301 USA.
 */

package org.ccnx.ccn.io;

import java.io.IOException;
import java.io.OutputStream;

import org.ccnx.ccn.CCNHandle;
import org.ccnx.ccn.impl.CCNSegmenter;
import org.ccnx.ccn.profiles.VersioningProfile;
import org.ccnx.ccn.protocol.CCNTime;
import org.ccnx.ccn.protocol.ContentName;
import org.ccnx.ccn.protocol.KeyLocator;
import org.ccnx.ccn.protocol.PublisherPublicKeyDigest;


public abstract class CCNAbstractOutputStream extends OutputStream {

	protected CCNHandle _handle = null;
	protected CCNSegmenter _segmenter = null;
	/** 
	 * The name for the content fragments, up to just before the sequence number.
	 */
	protected ContentName _baseName = null;
	protected KeyLocator _locator;
	protected PublisherPublicKeyDigest _publisher;

	/**
	 * The behavior of an output stream derived class is determined
	 * largely by its buffering, segmentation configuration (embodied
	 * in a CCNSegmenter) and flow control (embodied in a CCNFlowControl,
	 * contained within the segmenter).
	 * @param locator
	 * @param publisher
	 * @param segmenter
	 */
	public CCNAbstractOutputStream(KeyLocator locator, 
								   PublisherPublicKeyDigest publisher,
								   CCNSegmenter segmenter) {
		super();
		_segmenter = segmenter;
		_handle = _segmenter.getLibrary();
		if (null == _handle) {
			_handle = CCNHandle.getHandle();
		}

		// If these are null, the library defaults will be used.
		_locator = locator;
		_publisher = publisher;		
	}
	
	public CCNAbstractOutputStream() {}	// special purpose constructor
	
	/**
	 * Override in subclasses that need to do something special with start writes.
	 * @throws IOException
	 */
	protected void startWrite() throws IOException {}

	@Override
	public void write(byte[] b) throws IOException {
		write(b, 0, b.length);
	}

	@Override
	public void write(int b) throws IOException {
		byte buf[] = {(byte)b};
		write(buf, 0, 1);
	}

	public ContentName getBaseName() {
		return _baseName;
	}

	public CCNTime getVersion() {
		if (null == _baseName) 
			return null;
		return VersioningProfile.getTerminalVersionAsTimestampIfVersioned(_baseName);
	}

	public CCNSegmenter getSegmenter() {
		return _segmenter;
	}
	
	public void setTimeout(int timeout) {
		getSegmenter().setTimeout(timeout);
	}
}