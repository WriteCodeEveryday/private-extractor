/*
 * Copyright 2015, The Android Open Source Project
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package com.testing.PrivateExtractor;

import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;

import android.content.Context;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.content.pm.ResolveInfo;

import static androidx.test.core.app.ApplicationProvider.getApplicationContext;
import static androidx.test.platform.app.InstrumentationRegistry.getInstrumentation;
import androidx.test.filters.SdkSuppress;
import androidx.test.ext.junit.runners.AndroidJUnit4;
import androidx.test.uiautomator.By;
import androidx.test.uiautomator.BySelector;
import androidx.test.uiautomator.UiDevice;
import androidx.test.uiautomator.Until;

import static org.hamcrest.CoreMatchers.is;
import static org.hamcrest.CoreMatchers.notNullValue;
import static org.junit.Assert.assertThat;

/**
 * Basic sample for unbundled UiAutomator.
 */
@RunWith(AndroidJUnit4.class)
@SdkSuppress(minSdkVersion = 18)
public class ExtractFilesTest {
    private UiDevice mDevice = null;

    private static final String TARGET_PACKAGE
            = "edu.mit.privatekit";

    private static final int BASIC_TIMEOUT = 10000;

    public void startMainActivityFromHomeScreen() {
        if (mDevice == null) {
            // Initialize UiDevice instance
            mDevice = UiDevice.getInstance(getInstrumentation());
        }

        // Start from the home screen
        mDevice.pressHome();

        // Wait for launcher
        final String launcherPackage = getLauncherPackageName();
        assertThat(launcherPackage, notNullValue());
        mDevice.wait(Until.hasObject(By.pkg(launcherPackage).depth(0)), BASIC_TIMEOUT);

        // Launch the blueprint app
        Context context = getApplicationContext();
        final Intent intent = context.getPackageManager()
                .getLaunchIntentForPackage(TARGET_PACKAGE);
        intent.addFlags(Intent.FLAG_ACTIVITY_CLEAR_TASK);    // Clear out any previous instances
        context.startActivity(intent);

        // Wait for the app to appear
        mDevice.wait(Until.hasObject(By.pkg(TARGET_PACKAGE).depth(0)), BASIC_TIMEOUT);
    }

    @Test
    public void exportData() {
        startMainActivityFromHomeScreen();
        clickOnText("NEXT");
        clickOnText("Private Kit"); //Hack around an issue.
        clickOnText("NEXT");
        clickOnText("START");
        clickOnText("Export");
        clickOnText("SHARE");
        clickOnShareApp("PrivateExtractor");
    }

    private void clickOnText(String text) {
        BySelector item = By.textContains(text);

        //Attempt to click an item by text
        mDevice.wait(Until.hasObject(item), BASIC_TIMEOUT);
        mDevice.findObject(item).click();
    }

    private void clickOnShareApp(String text) {
        BySelector item = By.textContains(text);

        //Attempt to click an item by text
        mDevice.wait(Until.hasObject(item), BASIC_TIMEOUT);
        mDevice.findObject(item).getParent().click();

        item = By.clazz("android.widget.FrameLayout","com.testing.PrivateExtractor");
        mDevice.wait(Until.hasObject(item), BASIC_TIMEOUT); // A total hack to make sure the toast comes up.
    }

    /**
     * Uses package manager to find the package name of the device launcher. Usually this package
     * is "com.android.launcher" but can be different at times. This is a generic solution which
     * works on all platforms.`
     */
    private String getLauncherPackageName() {
        // Create launcher Intent
        final Intent intent = new Intent(Intent.ACTION_MAIN);
        intent.addCategory(Intent.CATEGORY_HOME);

        // Use PackageManager to get the launcher package name
        PackageManager pm = getApplicationContext().getPackageManager();
        ResolveInfo resolveInfo = pm.resolveActivity(intent, PackageManager.MATCH_DEFAULT_ONLY);
        return resolveInfo.activityInfo.packageName;
    }
}