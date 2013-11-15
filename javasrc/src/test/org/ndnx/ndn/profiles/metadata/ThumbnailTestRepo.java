/*
 * A NDNx library test.
 *
 * Portions Copyright (C) 2013 Regents of the University of California.
 * 
 * Based on the CCNx C Library by PARC.
 * Copyright (C) 2008-2013 Palo Alto Research Center, Inc.
 *
 * This work is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License version 2 as published by the
 * Free Software Foundation. 
 * This work is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License
 * for more details. You should have received a copy of the GNU General Public
 * License along with this program; if not, write to the
 * Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA 02110-1301, USA.
 */

package org.ndnx.ndn.profiles.metadata;

import java.io.IOException;

import org.ndnx.ndn.config.SystemConfiguration;
import org.ndnx.ndn.impl.NDNFlowControl;
import org.ndnx.ndn.impl.support.Log;
import org.ndnx.ndn.io.NDNInputStream;
import org.ndnx.ndn.io.RepositoryFileOutputStream;
import org.ndnx.ndn.io.content.NDNStringObject;
import org.ndnx.ndn.profiles.SegmentationProfile;
import org.ndnx.ndn.profiles.VersioningProfile;
import org.ndnx.ndn.profiles.metadata.ThumbnailProfile;
import org.ndnx.ndn.protocol.ContentName;
import org.ndnx.ndn.NDNTestBase;
import org.ndnx.ndn.NDNTestHelper;
import org.ndnx.ndn.io.NDNFileStreamTestRepo;
import org.junit.After;
import org.junit.AfterClass;
import org.junit.Assert;
import org.junit.Before;
import org.junit.BeforeClass;
import org.junit.Test;

public class ThumbnailTestRepo extends NDNTestBase {
	static NDNTestHelper testHelper = new NDNTestHelper(NDNFileStreamTestRepo.class);
	
	/**
	 * @throws java.lang.Exception
	 */
	@BeforeClass
	public static void setUpBeforeClass() throws Exception {
		NDNTestBase.setUpBeforeClass();
	}

	/**
	 * @throws java.lang.Exception
	 */
	@AfterClass
	public static void tearDownAfterClass() throws Exception {
		NDNTestBase.tearDownAfterClass();
	}

	/**
	 * @throws java.lang.Exception
	 */
	@Before
	public void setUp() throws Exception {
	}

	/**
	 * @throws java.lang.Exception
	 */
	@After
	public void tearDown() throws Exception {
	}
	
	@Test
	public void testThumbnails() throws Exception {
		Log.info(Log.FAC_TEST, "Starting testThumbnails");

		byte [] fakeImageData1 = "xxx".getBytes();
		ContentName thumbNailBase = new ContentName(testHelper.getTestNamespace("testThumbnails"), "thumbnailBaseFile");
		NDNStringObject cso = new NDNStringObject(thumbNailBase, "thumbNailBase", NDNFlowControl.SaveType.REPOSITORY, putHandle);
		cso.save();
		cso.close();
		ContentName origVersion = SegmentationProfile.segmentRoot(VersioningProfile.getLatestVersion(thumbNailBase, cso.getContentPublisher(), 
				SystemConfiguration.LONG_TIMEOUT, putHandle.defaultVerifier(), getHandle).name());		
		ContentName thumbName = ThumbnailProfile.getLatestVersion(thumbNailBase, "image.png".getBytes(),
					SystemConfiguration.LONG_TIMEOUT, putHandle);
		
		Log.info(Log.FAC_TEST, "Check that we can retrieve a simple thumbnail");
		RepositoryFileOutputStream thumbImage1 = new RepositoryFileOutputStream(thumbName, putHandle);
		thumbImage1.write(fakeImageData1, 0, fakeImageData1.length);
		thumbImage1.close();
		ContentName checkThumbName = ThumbnailProfile.getLatestVersion(thumbNailBase, "image.png".getBytes(),
				SystemConfiguration.LONG_TIMEOUT, putHandle);
		checkData(checkThumbName, fakeImageData1);
		
		Log.info(Log.FAC_TEST, "Check that we can retrieve a second version of a thumbnail");
		byte [] fakeImageData2 = "yyy".getBytes();
		ContentName thumbName2 = VersioningProfile.updateVersion(checkThumbName);
		RepositoryFileOutputStream thumbImage2 = new RepositoryFileOutputStream(thumbName2, putHandle);
		thumbImage2.write(fakeImageData2, 0, fakeImageData2.length);
		thumbImage2.close();
		
		checkThumbName = ThumbnailProfile.getLatestVersion(thumbNailBase, "image.png".getBytes(),
				SystemConfiguration.LONG_TIMEOUT, putHandle);
		checkData(checkThumbName, fakeImageData2);
		
		Log.info(Log.FAC_TEST, "Check that we can retrieve a thumbnail associated with a second version of a file");
		cso = new NDNStringObject(thumbNailBase, "thumbNailBase", NDNFlowControl.SaveType.REPOSITORY, putHandle);
		cso.save();
		cso.close();
		byte [] fakeImageData3 = "zzz".getBytes();
		thumbName = ThumbnailProfile.getLatestVersion(thumbNailBase, "image.png".getBytes(), SystemConfiguration.LONG_TIMEOUT, putHandle);
		RepositoryFileOutputStream thumbImage3 = new RepositoryFileOutputStream(thumbName, putHandle);
		thumbImage3.write(fakeImageData3, 0, fakeImageData3.length);
		thumbImage3.close();
		
		checkThumbName = ThumbnailProfile.getLatestVersion(thumbNailBase, "image.png".getBytes(), SystemConfiguration.LONG_TIMEOUT, putHandle);
		checkData(checkThumbName, fakeImageData3);
		
		Log.info(Log.FAC_TEST, "Check that we can retrieve a second thumbnail associated with a second version of a file");
		byte [] fakeImageData4 = "fff".getBytes();
		thumbName2 = VersioningProfile.updateVersion(checkThumbName);
		RepositoryFileOutputStream thumbImage4 = new RepositoryFileOutputStream(thumbName2, putHandle);
		thumbImage4.write(fakeImageData4, 0, fakeImageData4.length);
		thumbImage4.close();
		
		checkThumbName = ThumbnailProfile.getLatestVersion(thumbNailBase, "image.png".getBytes(), SystemConfiguration.LONG_TIMEOUT, putHandle);
		checkData(checkThumbName, fakeImageData4);

		Log.info(Log.FAC_TEST, "Check that we can retrieve the correct thumbnail associated with an arbitrary version of a file");
		checkThumbName = ThumbnailProfile.getLatestVersion(origVersion, "image.png".getBytes(), SystemConfiguration.LONG_TIMEOUT, putHandle);
		checkData(checkThumbName, fakeImageData2);
		
		Log.info(Log.FAC_TEST, "Completed testThumbnails");
	}
	
	private void checkData(ContentName name, byte[] check) throws IOException {
		NDNInputStream input = new NDNInputStream(name, getHandle);
		byte[] buffer = new byte[check.length];
		Assert.assertTrue(-1 != input.read(buffer));
		Assert.assertArrayEquals(buffer, check);
		input.close();		
	}
}