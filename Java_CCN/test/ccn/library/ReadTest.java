package test.ccn.library;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertTrue;

import java.util.ArrayList;
import java.util.Arrays;

import org.junit.Assert;
import org.junit.Test;

import com.parc.ccn.data.ContentName;
import com.parc.ccn.data.ContentObject;
import com.parc.ccn.data.query.BloomFilter;
import com.parc.ccn.data.query.CCNInterestListener;
import com.parc.ccn.data.query.ExcludeElement;
import com.parc.ccn.data.query.ExcludeFilter;
import com.parc.ccn.data.query.Interest;
import com.parc.ccn.data.util.DataUtils;
import com.parc.ccn.library.io.CCNWriter;
import com.parc.ccn.library.profiles.SegmentationProfile;

/**
 * 
 * @author rasmusse
 * 
 * NOTE: This test requires ccnd to be running
 *
 */

public class ReadTest extends LibraryTestBase implements CCNInterestListener {
	
	private static ArrayList<Integer> currentSet;
	
	private byte [] bloomSeed = "burp".getBytes();
	private ExcludeFilter ef = null;
	
	private String [] bloomTestValues = {
            "one", "two", "three", "four",
            "five", "six", "seven", "eight",
            "nine", "ten", "eleven", "twelve",
            "thirteen"
      	};
	
	private void excludeSetup() {
		BloomFilter bf1 = new BloomFilter(13, bloomSeed);
		ExcludeElement e1 = new ExcludeElement("aaa".getBytes(), bf1);
		ExcludeElement e2 = new ExcludeElement("zzzzzzzz".getBytes());
		
		for (String value : bloomTestValues) {
			bf1.insert(value.getBytes());
		}
		ArrayList<ExcludeElement>excludes = new ArrayList<ExcludeElement>(3);
		excludes.add(e1);
		excludes.add(e2);
		ef = new ExcludeFilter(excludes);
	}

	public ReadTest() throws Throwable {
		super();
	}
	
	@Test
	public void getNextTest() throws Throwable {
		System.out.println("getNext test started");
		CCNWriter writer = new CCNWriter("/getNext", putLibrary);
		for (int i = 0; i < count; i++) {
			Thread.sleep(rand.nextInt(50));
			writer.put("/getNext/" + Integer.toString(i), Integer.toString(count - i));
		}
		System.out.println("Put sequence finished");
		for (int i = 0; i < count; i++) {
			Thread.sleep(rand.nextInt(50));
			int tValue = rand.nextInt(count - 1);
			// DKS -- getNext was returning null here. Not clear what it's trying to do, could be interacting badly with
			// introduction of default fragment marker (which the above changes try to work around). Likely prefix count is wrong.
			// prefix of 1 should take care of that; though it's odd that that's a member of the name,
			// not the interest...
			ContentName cn = new ContentName(ContentName.fromNative("/getNext/" + new Integer(tValue).toString(), 1), ContentObject.contentDigest(Integer.toString(count - tValue)));
			ContentObject result = getLibrary.getNext(cn, 1000);
			checkResult(result, tValue + 1);
		}
		System.out.println("getNext test finished");
	}
	
	@Test
	public void getLatestTest() throws Throwable {
		int highest = 0;
		System.out.println("getLatest test started");
		CCNWriter writer = new CCNWriter("/getLatest", putLibrary);
		for (int i = 0; i < count; i++) {
			int tValue = getRandomFromSet(count, false);
			if (tValue > highest)
				highest = tValue;
			String name = "/getLatest/" + Integer.toString(tValue);
			System.out.println("Putting " + name);
			writer.put(name, Integer.toString(tValue));
			if (i > 1) {
				if (tValue == highest)
					tValue--;
				ContentName cn = SegmentationProfile.segmentName(ContentName.fromNative("/getNext/" + new Integer(tValue).toString(), 1), SegmentationProfile.baseSegment());
				ContentObject result = getLibrary.getLatest(cn, 5000);
				checkResult(result, highest);
			}
		}
		System.out.println("getLatest test finished");
	}
	
	@Test
	public void excludeFilterTest() throws Throwable {
		System.out.println("excludeFilterTest test started");
		excludeSetup();
		CCNWriter writer = new CCNWriter("/excludeFilterTest", putLibrary);
		for (String value : bloomTestValues) {
			writer.put("/excludeFilterTest/" + value, value);
		}
		writer.put("/excludeFilterTest/aaa", "aaa");
		writer.put("/excludeFilterTest/zzzzzzzz", "zzzzzzzz");
		Interest interest = Interest.constructInterest(ContentName.fromNative("/excludeFilterTest/"), ef, null);
		ContentObject content = getLibrary.get(interest, 1000);
		Assert.assertTrue(content == null);
		
		String shouldGetIt = "/excludeFilterTest/weShouldGetThis";
		writer.put(shouldGetIt, shouldGetIt);
		content = getLibrary.get(interest, 1000);
		Assert.assertFalse(content == null);
		assertEquals(content.name().toString(), shouldGetIt);
		System.out.println("excludeFilterTest test finished");
	}
	
	@Test
	public void getExcludeTest() throws Throwable {
		System.out.println("getExclude test started");
		// Try with single bloom filter
		excludeTest("/getExcludeTest1", Interest.OPTIMUM_FILTER_SIZE/2);
		// Try with multi part filter
		excludeTest("/getExcludeTest2", Interest.OPTIMUM_FILTER_SIZE + 5);
		System.out.println("getExclude test finished");
	}
	
	private void excludeTest(String prefix, int nFilters) throws Throwable {
	
		System.out.println("Starting exclude test - nFilters is " + nFilters);
		CCNWriter writer = new CCNWriter(prefix, putLibrary);
		byte [][] excludes = new byte[nFilters - 1][];
		for (int i = 0; i < nFilters; i++) {
			String value = new Integer(i).toString();
			if (i < (nFilters - 1))
				excludes[i] = value.getBytes();
			String name = prefix + "/" + value;
			writer.put(name, value);
		}
		ContentObject content = getLibrary.getExcept(ContentName.fromNative(prefix + "/"), excludes, 50000);
		if (null == content || !Arrays.equals(content.content(), new Integer((nFilters - 1)).toString().getBytes())) {
			// Try one more time in case we got a false positive
			content = getLibrary.getExcept(ContentName.fromNative(prefix + "/"), excludes, 50000);
		}
		Assert.assertFalse(content == null);
		assertEquals(DataUtils.compare(content.content(), new Integer((nFilters - 1)).toString().getBytes()), 0);
	}

	public Interest handleContent(ArrayList<ContentObject> results, Interest interest) {
		return null;
	}
	
	private void checkResult(ContentObject result, int value) {
		assertTrue(result != null);
		String resultAsString = SegmentationProfile.segmentRoot(result.name()).toString();
		int sep = resultAsString.lastIndexOf('/');
		assertTrue(sep > 0);
		int resultValue = Integer.parseInt(resultAsString.substring(sep + 1));
		assertEquals(new Integer(value), new Integer(resultValue));
	}
	
	public int getRandomFromSet(int length, boolean reset) {
		int result = -1;
		if (reset || currentSet == null)
			currentSet = new ArrayList<Integer>(length);
		if (currentSet.size() >= length)
			return result;
		while (true) {
			result = rand.nextInt(length);
			boolean found = false;
			for (int used : currentSet) {
				if (used == result) {
					found = true;
					break;
				}
			}
			if (!found)
				break;
		}
		currentSet.add(result);
		return result;
	}

}
