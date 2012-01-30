////////////////////////////////////////////////////////////////////////////////
//
//  ADOBE SYSTEMS INCORPORATED
//  Copyright 2004-2010 Adobe Systems Incorporated
//  All Rights Reserved.
//
//  NOTICE: Adobe permits you to use, modify, and distribute this file
//  in accordance with the terms of the license agreement accompanying it.
//
////////////////////////////////////////////////////////////////////////////////

package spark.components
{
import flash.display.DisplayObject;
import flash.events.TimerEvent;
import flash.net.URLRequest;
import flash.text.TextFieldType;
import flash.utils.Timer;

import mx.controls.listClasses.*;
import mx.core.IFlexDisplayObject;
import mx.core.IVisualElement;
import mx.core.UIComponentGlobals;
import mx.core.UITextField;
import mx.core.UITextFormat;
import mx.core.mx_internal;
import mx.graphics.BitmapFillMode;
import mx.graphics.BitmapScaleMode;
import mx.styles.CSSStyleDeclaration;

import spark.components.supportClasses.StyleableTextField;
import spark.core.ContentCache;
import spark.core.DisplayObjectSharingMode;
import spark.core.IContentLoader;
import spark.core.IGraphicElement;
import spark.core.IGraphicElementContainer;
import spark.core.ISharedDisplayObject;
import spark.primitives.BitmapImage;

use namespace mx_internal;

//--------------------------------------
//  Styles
//--------------------------------------

include "../styles/metadata/GapStyles.as"

/**
 *  The delay value before attempting to load the 
 *  icon's source if it has not been cached already.
 * 
 *  <p>The reason a delay is useful is while scrolling around, you 
 *  don't necessarily want the image to load up immediately.  Instead, 
 *  you should wait a certain delay period to make sure the user actually 
 *  wants to see this item renderer.</p>
 * 
 *  @default 500
 *  
 *  @langversion 3.0
 *  @playerversion Flash 10
 *  @playerversion AIR 2.5
 *  @productversion Flex 4.5
 */
[Style(name="iconDelay", type="Number", format="Time", inherit="no")]

/**
 *  Name of the CSS Style declaration to use for the styles for the
 *  message component.
 * 
 *  @default iconItemRendererMessageStyle
 *  
 *  @langversion 3.0
 *  @playerversion Flash 10
 *  @playerversion AIR 2.5
 *  @productversion Flex 4.5
 */
[Style(name="messageStyleName", type="String", inherit="no")]

// FIXME (rfrishbe): add verticalGap

/**
 *  The IconItemRenderer class is a performant item 
 *  renderer optimized for mobile devices.  
 *  It displays four optional parts for each item in the 
 *  list-based control: 
 *
 *  <ul>
 *    <li>An icon on the left defined by the <code>iconField</code> property.</li>
 *    <li>A single-line text label next to the icon defined by the 
 *      <code>labelField</code> or <code>labelFunction</code> property.</li>
 *    <li>A multi-line message below the text label defined by the 
 *      <code>messageField</code> or <code>messageFunction</code> property.</li>
 *    <li>A decorator icon on the right defined by the 
 *      <code>decoratorClass</code> property.</li>
 *  </ul>
 *
 *  <p>To apply CSS styles to the single-line text label, such as font size and color, 
 *  set the styles on the IconItemRenderer class. 
 *  To set styles on the multi-line message, use the <code>messageStyleNameM</code> style property. 
 *  The following example sets the text styles for both the text label and message:</p>
 *
 *  <pre>
 *     &lt;fx:Style&gt;
 *         .myFontStyle { 
 *             fontSize: 15;
 *             color: #9933FF;
 *         }
 *  
 *     &lt;/fx:Style&gt;
 *     
 *     &lt;s:List id="myList"
 *         width="100%" height="100%"
 *         labelField="firstName"&gt;
 *         &lt;s:itemRenderer&gt;
 *             &lt;fx:Component&gt;
 *                 &lt;s:IconItemRenderer messageStyleName="myFontStyle" fontSize="25"
 *                     labelField="firstName"
 *                     messageField="lastName" 
 *                     decoratorClass="&#64;Embed(source='assets/logo_small.jpg')"/&gt;
 *             &lt;/fx:Component&gt;
 *         &lt;/s:itemRenderer&gt;
 *         &lt;s:ArrayCollection&gt;
 *             &lt;fx:Object firstName="Dave" lastName="Duncam" company="Adobe" phone="413-555-1212"/&gt;
 *             &lt;fx:Object firstName="Sally" lastName="Smith" company="Acme" phone="617-555-1491"/&gt;
 *             &lt;fx:Object firstName="Jim" lastName="Jackson" company="Beta" phone="413-555-2345"/&gt;
 *             &lt;fx:Object firstName="Mary" lastName="Moore" company="Gamma" phone="617-555-1899"/&gt;
 *         &lt;/s:ArrayCollection&gt;
 *     &lt;/s:List&gt;
 *  </pre>
 *
 *  @see spark.components.List
 *  @see mx.core.IDataRenderer
 *  @see spark.components.IItemRenderer
 *  @see spark.components.supportClasses.ItemRenderer
 *  @see spark.components.LabelItemRenderer
 *  
 *  @langversion 3.0
 *  @playerversion Flash 10
 *  @playerversion AIR 2.5
 *  @productversion Flex 4.5
 */
public class IconItemRenderer extends LabelItemRenderer 
    implements IGraphicElementContainer, ISharedDisplayObject
{
    
    //--------------------------------------------------------------------------
    //
    //  Class constants
    //
    //--------------------------------------------------------------------------
    
    /**
     *  @private
     *  Static icon image cache.  This is the default for iconContentLoader.
     */
    mx_internal static var _imageCache:ContentCache;
    
    //--------------------------------------------------------------------------
    //
    //  Constructor
    //
    //--------------------------------------------------------------------------
    
    /**
     *  Constructor.
     *  
     *  @langversion 3.0
     *  @playerversion Flash 10
     *  @playerversion AIR 2.5
     *  @productversion Flex 4.5
     */
    public function IconItemRenderer()
    {
        super();
        
        if (_imageCache == null) {
            _imageCache = new ContentCache();
            _imageCache.enableCaching = true;
            _imageCache.maxCacheEntries = 100;
        }
    }
    
    //--------------------------------------------------------------------------
    //
    //  Variables
    //
    //--------------------------------------------------------------------------
    
    /**
     *  @private
     *  Stores the text of the label component.  This is calculated in 
     *  commitProperties() based on labelFunction, labelField, and label.
     * 
     *  <p>We can't just use labelDisplay.text because it may contain 
     *  a truncated value.</p>
     */
    private var labelText:String = "";
    
    /**
     *  @private
     *  Stores the text of the message component.  This is calculated in 
     *  commitProperties() based on messageField and messageFunction.
     * 
     *  <p>We can't just use messageDisplay.text because it may contain 
     *  a truncated value (Technically we don't truncate message's text 
     *  at the moment because it's multi-line text, but in the future 
     *  we may not do that, and this feels more consistent with 
     *  how we deal with labels, so we still keep this "extra"
     *  variable around even though technically it's not needed).</p>
     */
    private var messageText:String = "";
    
    /**
     *  @private
     *  Since iconDisplay is a GraphicElement, we have to call its lifecycle methods 
     *  directly.
     */
    private var iconNeedsValidateProperties:Boolean = false;
    
    /**
     *  @private
     *  Since iconDisplay is a GraphicElement, we have to call its lifecycle methods 
     *  directly.
     */
    private var iconNeedsValidateSize:Boolean = false;
    
    /**
     *  @private
     *  Since iconDisplay is a GraphicElement, we have to call help assign 
     *  its display object
     */
    private var iconNeedsDisplayObjectAssignment:Boolean = false;
    
    /**
     *  @private
     *  Timer, used to delay setting the source on the icon.
     */
    private var iconSetterDelayTimer:Timer;
    
    /**
     *  @private
     *  The source to set iconDisplay to, after waiting an appropriate delay period
     */
    private var loadingIconSource:Object;
    
    //--------------------------------------------------------------------------
    //
    //  Public Properties: Overridden
    //
    //--------------------------------------------------------------------------
    
    /**
     *  @private
     */
    override public function set data(value:Object):void
    {
        // FIXME (rfrishbe): early return if the data object has not changed. 
        // This should be removed when SDK-28656 is fixed.
        if (data == value)
            return;
        
        super.data = value;
        
        iconChanged = true;
        labelChanged = true;
        messageChanged = true;
        
        invalidateProperties();
    }
    
    /**
     *  <p>If <code>labelFunction</code> = <code>labelField</code> = null,
     *  then use the <code>label</code> property that gets 
     *  pushed in from the list control. 
     *  However if <code>labelField</code> is explicitly set to 
     *  <code>""</code> (the empty string),
     *  then no label appears.</p>
     * 
     *  @inheritDoc
     * 
     *  @see spark.components.IconItemRenderer#labelField
     *  @see spark.components.IconItemRenderer#labelFunction
     *  @see spark.components.IItemRenderer#label
     * 
     *  @langversion 3.0
     *  @playerversion Flash 10
     *  @playerversion AIR 2.5
     *  @productversion Flex 4.5   
     */
    override public function set label(value:String):void
    {
		if (value == label)
			return;
		
        super.label = value;
        
        labelChanged = true;
        invalidateProperties();
    }
    
    //--------------------------------------------------------------------------
    //
    //  Public Properties
    //
    //--------------------------------------------------------------------------
    
    //----------------------------------
    //  iconContentLoader
    //----------------------------------
    
    /**
     *  @private 
     */ 
    private var _iconContentLoader:IContentLoader = _imageCache;
    
    
    /**
     *  Optional custom image loader, such as an image cache or queue, to
     *  associate with content loader client.
     * 
     *  <p>The default value is a static content cache defined on IconItemRenderer
     *  that allows up to 100 entries.</p>
     * 
     *  @langversion 3.0
     *  @playerversion Flash 10
     *  @playerversion AIR 2.5
     *  @productversion Flex 4.5   
     */
    public function get iconContentLoader():IContentLoader
    {
        return _iconContentLoader;
    }
    
    /**
     *  @private
     */ 
    public function set iconContentLoader(value:IContentLoader):void
    {
        if (value == _iconContentLoader)
            return;
        
        _iconContentLoader = value;
        
        if (iconDisplay)
            iconDisplay.contentLoader = _iconContentLoader;
    }
    
    //----------------------------------
    //  decoratorClass
    //----------------------------------
    
    /**
     *  @private 
     */ 
    private var _decoratorClass:Class;
    
    /**
     *  @private 
     */ 
    private var decoratorClassChanged:Boolean;
    
    /**
     *  The display object component used to 
     *  display the decorator for this item renderer.
     * 
     *  @langversion 3.0
     *  @playerversion Flash 10
     *  @playerversion AIR 2.5
     *  @productversion Flex 4.5
     */ 
    protected var decoratorDisplay:DisplayObject;
    
    /**
     *  The decorator icon that appears on the right side 
     *  of this item renderer.
     * 
     *  <p>The decorator icon ignores the <code>verticalAlign</code> style
     *  and is always centered vertically.</p>
     *
     *  @default "" 
     * 
     *  @langversion 3.0
     *  @playerversion Flash 10
     *  @playerversion AIR 2.5
     *  @productversion Flex 4.5   
     */
    public function get decoratorClass():Class
    {
        return _decoratorClass;
    }
    
    /**
     *  @private
     */ 
    public function set decoratorClass(value:Class):void
    {
        if (value == _decoratorClass)
            return;
        
        _decoratorClass = value;
        
        decoratorClassChanged = true;
        invalidateProperties();
    }
    
    //----------------------------------
    //  labelField
    //----------------------------------
    
    /**
     *  @private
     */
    private var _labelField:String = null;
    
    /**
     *  @private
     */
    private var labelFieldOrFunctionChanged:Boolean;
    
    /**
     *  @private
     */
    private var labelChanged:Boolean; 
    
    /**
     *  The name of the field in the data provider items to display 
     *  as the label. 
     *  The <code>labelFunction</code> property overrides this property.
     * 
     *  <p>If <code>labelFunction</code> = <code>labelField</code> = null,
     *  then use the <code>label</code> property that gets 
     *  pushed in from the list-based control.  
     *  However if <code>labelField</code> is explicitly set to 
     *  <code>""</code> (the empty string),
     *  then no label appears.</p>
     * 
     *  @see spark.components.IconItemRenderer#labelFunction
     *  @see spark.components.IItemRenderer#label
     *
     *  @default null
     *  
     *  @langversion 3.0
     *  @playerversion Flash 10
     *  @playerversion AIR 2.5
     *  @productversion Flex 4.5
     */
    public function get labelField():String
    {
        return _labelField;
    }
    
    /**
     *  @private
     */
    public function set labelField(value:String):void
    {
        if (value == _labelField)
            return;
            
        _labelField = value;
        labelFieldOrFunctionChanged = true;
        labelChanged = true;
        
        invalidateProperties();
    }
    
    //----------------------------------
    //  labelFunction
    //----------------------------------
    
    /**
     *  @private
     */
    private var _labelFunction:Function; 
    
    /**
     *  A user-supplied function to run on each item to determine its label.  
     *  The <code>labelFunction</code> property overrides 
     *  the <code>labelField</code> property.
     *
     *  <p>You can supply a <code>labelFunction</code> that finds the 
     *  appropriate fields and returns a displayable string. The 
     *  <code>labelFunction</code> is also good for handling formatting and 
     *  localization.</p>
     *
     *  <p>The label function takes a single argument which is the item in 
     *  the data provider and returns a String.</p>
     *  <pre>
     *  myLabelFunction(item:Object):String</pre>
     * 
     *  <p>If <code>labelFunction</code> = <code>labelField</code> = null,
     *  then use the <code>label</code> property that gets 
     *  pushed in from the list-based control.  
     *  However if <code>labelField</code> is explicitly set to 
     *  <code>""</code> (the empty string),
     *  then no label appears.</p>
     * 
     *  @see spark.components.IconItemRenderer#labelFunction
     *  @see spark.components.IItemRenderer#label
     *
     *  @default null
     *  
     *  @langversion 3.0
     *  @playerversion Flash 10
     *  @playerversion AIR 2.5
     *  @productversion Flex 4.5
     */
    public function get labelFunction():Function
    {
        return _labelFunction;
    }
    
    /**
     *  @private
     */
    public function set labelFunction(value:Function):void
    {
        if (value == _labelFunction)
            return;
            
        _labelFunction = value;
        labelFieldOrFunctionChanged = true;
        labelChanged = true;
        
        invalidateProperties(); 
    }
    
    //----------------------------------
    //  iconField
    //----------------------------------
    
    /**
     *  @private 
     */ 
    private var _iconField:String;
    
    /**
     *  @private 
     */ 
    private var iconFieldOrFunctionChanged:Boolean;
    
    /**
     *  @private 
     */ 
    private var iconChanged:Boolean;
    
    /**
     *  @private
     *  The class to use when instantiating the icon for IconItemRenderer.
     *  This class must extend spark.primitives.BitmapImage.
     *  This property was added for Design View so they can set this to a special
     *  subclass of BitmapImage that knows how to load and resolve resources in Design View.
     */
    mx_internal var iconDisplayClass:Class = BitmapImage;
    
    /**
     *  The bitmap image component used to 
     *  display the icon data of the item renderer.
     * 
     *  <p>Because IconItemRenderer implements ISharedDisplayObject 
     *  and IGraphicElementContainer, we don't need to wrap iconDisplay 
     *  in a Group; however, it does require a little more work when instantiating 
     *  and destroying iconDisplay.</p>
     * 
     *  @langversion 3.0
     *  @playerversion Flash 10
     *  @playerversion AIR 2.5
     *  @productversion Flex 4.5
     */
    protected var iconDisplay:BitmapImage;
    
    /**
     *  The name of the field in the data item to display as the icon. 
     *  By default <code>iconField</code> is <code>null</code>, and the item renderer 
     *  does not display an icon.
     *
     *  @default null
     * 
     *  @langversion 3.0
     *  @playerversion Flash 10
     *  @playerversion AIR 2.5
     *  @productversion Flex 4.5
     */
    public function get iconField():String
    {
        return _iconField;
    }
    
    /**
     *  @private
     */ 
    public function set iconField(value:String):void
    {
        if (value == _iconField)
            return;
        
        _iconField = value;
        iconFieldOrFunctionChanged = true;
        iconChanged = true;
        
        invalidateProperties();
    }
    
    //----------------------------------
    //  iconFillMode
    //----------------------------------
    
    /**
     *  @private 
     */ 
    private var _iconFillMode:String = BitmapFillMode.SCALE;
    
    [Inspectable(category="General", enumeration="clip,repeat,scale", defaultValue="scale")]
    
    /**
     *  @copy spark.primitives.BitmapImage#fillMode
     *
     *  @default <code>mx.graphics.BitmapFillMode.SCALE</code>
     *
     *  @see mx.graphics.BitmapFillMode
     * 
     *  @langversion 3.0
     *  @playerversion Flash 10
     *  @playerversion AIR 2.5
     *  @productversion Flex 4.5
     */
    public function get iconFillMode():String
    {
        return _iconFillMode;
    }
    
    /**
     *  @private
     */ 
    public function set iconFillMode(value:String):void
    {
        if (value == _iconFillMode)
            return;
        
        _iconFillMode = value;
        
        if (iconDisplay)
            iconDisplay.fillMode = _iconFillMode;
    }
    
    //----------------------------------
    //  iconFunction
    //----------------------------------
    
    /**
     *  @private 
     */ 
    private var _iconFunction:Function;
    
    /**
     *  A user-supplied function to run on each item to determine its icon.  
     *  The <code>iconFunction</code> property overrides 
     *  the <code>iconField</code> property.
     *
     *  <p>You can supply an <code>iconFunction</code> that finds the 
     *  appropriate fields and returns a valid URL or object to be used as 
     *  the icon.</p>
     *
     *  <p>The icon function takes a single argument which is the item in 
     *  the data provider and returns an Object that gets passed to a 
     *  <code>spark.primitives.BitmapImage</code> object as the <code>source</code>
     *  property.  Icon function can return a valid URL pointing to an image 
     *  or a Class file that represents an image.  To see what other types 
     *  of objects can be returned from the icon 
     *  function, see the <code>BitmapImage</code>'s documentation</p>
     *  <pre>
     *  myIconFunction(item:Object):Object</pre>
     *
     *  @default null
     * 
     *  @see spark.primitives.BitmapImage#source
     *  
     *  @langversion 3.0
     *  @playerversion Flash 10
     *  @playerversion AIR 2.5
     *  @productversion Flex 4.5
     */
    public function get iconFunction():Function
    {
        return _iconFunction;
    }
    
    /**
     *  @private
     */ 
    public function set iconFunction(value:Function):void
    {
        if (value == _iconFunction)
            return;
        
        _iconFunction = value;
        iconFieldOrFunctionChanged = true;
        iconChanged = true;
        
        invalidateProperties();
    }
    
    //----------------------------------
    //  iconHeight
    //----------------------------------
    
    /**
     *  @private 
     */ 
    private var _iconHeight:Number;
    
    /**
     *  The height of the icon.  If unspecified, the 
     *  intrinsic height of the image is used.
     *
     *  @default NaN
     * 
     *  @langversion 3.0
     *  @playerversion Flash 10
     *  @playerversion AIR 2.5
     *  @productversion Flex 4.5
     */
    public function get iconHeight():Number
    {
        return _iconHeight;
    }
    
    /**
     *  @private
     */ 
    public function set iconHeight(value:Number):void
    {
        if (value == _iconHeight)
            return;
        
        _iconHeight = value;
        
        invalidateSize();
        invalidateDisplayList();
    }
    
    //----------------------------------
    //  iconScaleMode
    //----------------------------------
    
    /**
     *  @private 
     */ 
    private var _iconScaleMode:String = BitmapScaleMode.STRETCH;
    
    [Inspectable(category="General", enumeration="stretch,letterbox", defaultValue="stretch")]
    
    /**
     *  @copy spark.primitives.BitmapImage#scaleMode
     *
     *  @default <code>mx.graphics.BitmapScaleMode.STRETCH</code>
     *
     *  @see mx.graphics.BitmapScaleMode
     * 
     *  @langversion 3.0
     *  @playerversion Flash 10
     *  @playerversion AIR 2.5
     *  @productversion Flex 4.5
     */
    public function get iconScaleMode():String
    {
        return _iconScaleMode;
    }
    
    /**
     *  @private
     */ 
    public function set iconScaleMode(value:String):void
    {
        if (value == _iconScaleMode)
            return;
        
        _iconScaleMode = value;
        
        if (iconDisplay)
            iconDisplay.scaleMode = _iconScaleMode;
    }
    
    //----------------------------------
    //  iconWidth
    //----------------------------------
    
    /**
     *  @private 
     */ 
    private var _iconWidth:Number;
    
    /**
     *  The width of the icon.  If unspecified, the 
     *  intrinsic width of the image is used.
     *
     *  @default NaN
     * 
     *  @langversion 3.0
     *  @playerversion Flash 10
     *  @playerversion AIR 2.5
     *  @productversion Flex 4.5
     */
    public function get iconWidth():Number
    {
        return _iconWidth;
    }
    
    /**
     *  @private
     */ 
    public function set iconWidth(value:Number):void
    {
        if (value == _iconWidth)
            return;
        
        _iconWidth = value;
        
        invalidateSize();
        invalidateDisplayList();
    }
    
    //----------------------------------
    //  messageField
    //----------------------------------
    
    /**
     *  @private
     */
    private var _messageField:String;
    
    /**
     *  The text component used to 
     *  display the message data of the item renderer.
     * 
     *  @langversion 3.0
     *  @playerversion Flash 10
     *  @playerversion AIR 2.5
     *  @productversion Flex 4.5
     */
    protected var messageDisplay:StyleableTextField;
    
    /**
     *  @private
     */
    private var messageFieldOrFunctionChanged:Boolean;
    
    /**
     *  @private
     */
    private var messageChanged:Boolean;
    
    /**
     *  The name of the field in the data items to display 
     *  as the message. 
     *  The <code>messageFunction</code> property overrides this property.
     *
     *  <p>Use the <code>messageStyleName</code> style to control the 
     *  appearance of the text.</p>
     *
     *  @default null
     *  
     *  @langversion 3.0
     *  @playerversion Flash 10
     *  @playerversion AIR 2.5
     *  @productversion Flex 4.5
     */
    public function get messageField():String
    {
        return _messageField;
    }
    
    /**
     *  @private
     */
    public function set messageField(value:String):void
    {
        if (value == _messageField)
            return;
        
        _messageField = value;
        messageFieldOrFunctionChanged = true;
        messageChanged = true;
        
        invalidateProperties();
    }
    
    //----------------------------------
    //  messageFunction
    //----------------------------------
    
    /**
     *  @private
     */
    private var _messageFunction:Function;
    
    /**
     *  A user-supplied function to run on each item to determine its message.  
     *  The <code>messageFunction</code> property overrides 
     *  the <code>messageField</code> property.
     *
     *  <p>You can supply a <code>messageFunction</code> that finds the 
     *  appropriate fields and returns a displayable string. The 
     *  <code>messageFunction</code> is also good for handling formatting and 
     *  localization.</p>
     *
     *  <p>The message function takes a single argument which is the item in 
     *  the data provider and returns a String.</p>
     *  <pre>
     *  myMessageFunction(item:Object):String</pre>
     *
     *  @default null
     *  
     *  @langversion 3.0
     *  @playerversion Flash 10
     *  @playerversion AIR 2.5
     *  @productversion Flex 4.5
     */
    public function get messageFunction():Function
    {
        return _messageFunction;
    }
    
    /**
     *  @private
     */
    public function set messageFunction(value:Function):void
    {
        if (value == _messageFunction)
            return;
        
        _messageFunction = value;
        messageFieldOrFunctionChanged = true;
        messageChanged = true;
        
        invalidateProperties(); 
    }
    
    //----------------------------------
    //  redrawRequested
    //----------------------------------
    
    /**
     *  @private
     */
    private var _redrawRequested:Boolean = false;
    
    /**
     *  @inheritDoc
     * 
     *  <p>We implement this as part of ISharedDisplayObject so the iconDisplay 
     *  can share our display object.</p>
     *  
     *  @langversion 3.0
     *  @playerversion Flash 10
     *  @playerversion AIR 1.5
     *  @productversion Flex 4
     */
    public function get redrawRequested():Boolean
    {
        return _redrawRequested;
    }
    
    /**
     *  @private
     */
    public function set redrawRequested(value:Boolean):void
    {
        _redrawRequested = value;
    }
    
    //--------------------------------------------------------------------------
    //
    //  IGraphicElementContainer
    //
    //--------------------------------------------------------------------------
    
    /**
     *  Notify the host that an element layer has changed.
     *
     *  The <code>IGraphicElementHost</code> must re-evaluates the sequences of 
     *  graphic elements with shared DisplayObjects and may need to re-assign the 
     *  DisplayObjects and redraw the sequences as a result. 
     * 
     *  Typically the host will perform this in its 
     *  <code>validateProperties()</code> method.
     *
     *  @param element The element that has changed size.
     * 
     *  @langversion 3.0
     *  @playerversion Flash 10
     *  @playerversion AIR 2.0
     *  @productversion Flex 4.5
     */
    public function invalidateGraphicElementSharing(element:IGraphicElement):void
    {
        // since the only graphic element is hooked up to drawing with the background,
        // just invalidate display list
        iconNeedsDisplayObjectAssignment = true;
        invalidateProperties();
    }
    
    /**
     *  Notify the host component that an element changed and needs to validate properties.
     * 
     *  The <code>IGraphicElementHost</code> must call the <code>validateProperties()</code>
     *  method on the IGraphicElement to give it a chance to commit its properties.
     * 
     *  Typically the host will validate the elements' properties in its
     *  <code>validateProperties()</code> method.
     *
     *  @param element The element that has changed.
     * 
     *  @langversion 3.0
     *  @playerversion Flash 10
     *  @playerversion AIR 2.0
     *  @productversion Flex 4.5
     */
    public function invalidateGraphicElementProperties(element:IGraphicElement):void
    {
        iconNeedsValidateProperties = true;
        invalidateProperties();
    }
    
    /**
     *  Notify the host component that an element size has changed.
     * 
     *  The <code>IGraphicElementHost</code> must call the <code>validateSize()</code>
     *  method on the IGraphicElement to give it a chance to validate its size.
     * 
     *  Typically the host will validate the elements' size in its
     *  <code>validateSize()</code> method.
     *
     *  @param element The element that has changed size.
     * 
     *  @langversion 3.0
     *  @playerversion Flash 10
     *  @playerversion AIR 2.0
     *  @productversion Flex 4.5
     */
    public function invalidateGraphicElementSize(element:IGraphicElement):void
    {
        iconNeedsValidateSize = true;
        invalidateSize();
    }
    
    /**
     *  Notify the host component that an element has changed and needs to be redrawn.
     * 
     *  The <code>IGraphicElementHost</code> must call the <code>validateDisplayList()</code>
     *  method on the IGraphicElement to give it a chance to redraw.
     * 
     *  Typically the host will validate the elements' display lists in its
     *  <code>validateDisplayList()</code> method.
     *
     *  @param element The element that has changed.
     * 
     *  @langversion 3.0
     *  @playerversion Flash 10
     *  @playerversion AIR 2.0
     *  @productversion Flex 4.5
     */
    public function invalidateGraphicElementDisplayList(element:IGraphicElement):void
    {
        if (element.displayObject is ISharedDisplayObject)
            ISharedDisplayObject(element.displayObject).redrawRequested = true;
        
        invalidateDisplayList();
    }
    
    //--------------------------------------------------------------------------
    //
    //  Overridden methods: UIComponent
    //
    //--------------------------------------------------------------------------
    
    /**
     *  @private
     */
    override protected function createChildren():void
    {
        super.createChildren();
        
        // create any children you need in here
        
        // iconDisplay, messageDisplay, and decoratorDisplay are created in 
        // commitProperties() since they are dependent on 
        // other properties and we don't always create them
        // labelText just uses labelElement to display its data
    }
    
    /**
     *  @private
     */
    override public function styleChanged(styleName:String):void
    {
        var allStyles:Boolean = !styleName || styleName == "styleName";
        
        super.styleChanged(styleName);
        
        // if message styles may have changed, let's null out the old 
        // value and notify messageDisplay
        if (allStyles || styleName == "messageStyleName")
        {
            if (messageDisplay)
            {
                var messageStyleName:String = getStyle("messageStyleName");
                if (messageStyleName)
                {
                    var styleDecl:CSSStyleDeclaration =
                        styleManager.getMergedStyleDeclaration("." + messageStyleName);
                    
                    if (styleDecl)
                    {
                        messageDisplay.styleDeclaration = styleDecl;
                        messageDisplay.styleChanged("styleName");
                    }
                }
            }
        }
    }
    
    /**
     *  @private
     */
    override protected function commitProperties():void
    {
        super.commitProperties();
        
        if (decoratorClassChanged)
        {
            decoratorClassChanged = false;
            
            // if there's an old one, remove it
            if (decoratorDisplay)
            {
                removeChild(decoratorDisplay);
                decoratorDisplay = null;
            }
            
            // if we need to create it, do it here
            if (decoratorClass)
            {
                decoratorDisplay = new _decoratorClass();
                addChild(decoratorDisplay);
            }
            
            invalidateSize();
            invalidateDisplayList();
        }
        
        if (iconFieldOrFunctionChanged)
        {
            iconFieldOrFunctionChanged = false;
            
            // let's see if we need to create or remove it
            if ((iconField || (iconFunction != null)) && !iconDisplay)
            {
                // need to create it
                
                iconDisplay = new iconDisplayClass();
                
                iconDisplay.contentLoader = iconContentLoader;
                iconDisplay.fillMode = iconFillMode;
                iconDisplay.scaleMode = iconScaleMode;

                iconDisplay.parentChanged(this);
                
                iconNeedsDisplayObjectAssignment = true;
            }
            else if (!(iconField || (iconFunction != null)) && iconDisplay)
            {
                // need to remove the display object
                var oldDisplayObject:DisplayObject = iconDisplay.displayObject;
                if (oldDisplayObject)
                { 
                    // If the element created the display object
                    if (iconDisplay.displayObjectSharingMode != DisplayObjectSharingMode.USES_SHARED_OBJECT &&
                        oldDisplayObject.parent == this)
                    {
                        removeChild(oldDisplayObject);
                    }
                }
                
                iconDisplay.parentChanged(null);
                iconDisplay = null;
            }
            
            invalidateSize();
            invalidateDisplayList();
        }
        
        if (messageFieldOrFunctionChanged)
        {
            messageFieldOrFunctionChanged = false;
            
            // let's see if we need to create or remove it
            if ((messageField || (messageFunction != null)) && !messageDisplay)
            {
                // get styles for this text component
                
                // need to create it
                messageDisplay = StyleableTextField(createInFontContext(StyleableTextField));
                messageDisplay.styleName = this;
                messageDisplay.editable = false;
                messageDisplay.selectable = false;
                messageDisplay.multiline = true;
                messageDisplay.wordWrap = true;
                
                var messageStyleName:String = getStyle("messageStyleName");
                if (messageStyleName)
                {
                    var styleDecl:CSSStyleDeclaration =
                        styleManager.getMergedStyleDeclaration("." + messageStyleName);
                    
                    if (styleDecl)
                        messageDisplay.styleDeclaration = styleDecl;
                }
                
                addChild(messageDisplay);
            }
            else if (!(messageField || (messageFunction != null)) && messageDisplay)
            {
                // need to remove it
                removeChild(messageDisplay);
                messageDisplay = null;
            }
            
            invalidateSize();
            invalidateDisplayList();
        }
        
        // label is created in super.createChildren()
        
        if (iconChanged)
        {
            iconChanged = false;
            
            // we set the icon after a delay for performance benefits and 
            // so we can cancel the load if we're scrolling fast
            // we still grab the source here so we can make sure we don't
            // cancel a load when the data is reset (if the source is the same)
            // if icon, try setting that
            
            if (iconFunction != null)
            {
                setIconDisplaySource(iconFunction(data));
            }
            else if (iconField)
            {
                try
                {
                    if (iconField in data)
                    {
                        setIconDisplaySource(data[iconField]);
                    }
                }
                catch(e:Error)
                {
                    setIconDisplaySource(null);
                }
            }
        }
        
        if (messageChanged)
        {
            messageChanged = false;
            
            if (messageFunction != null)
            {
                messageText = messageFunction(data);
                messageDisplay.text = messageText;
            }
            else if (messageField)
            {
                try
                {
                    if (messageField in data && data[messageField] != null)
                    {
                        messageText = data[messageField];
                        messageDisplay.text = messageText;
                    }
                    else
                    {
                        messageText = "";
                        messageDisplay.text = messageText;
                    }
                }
                catch(e:Error)
                {
                    messageText = "";
                    messageDisplay.text = messageText;
                }
            }
        }
        
        if (labelChanged)
        {
            labelChanged = false;
            
            // if label, try setting that
            if (labelFunction != null)
            {
                labelText = labelFunction(data);
                if (!labelDisplay)
                    createLabelDisplay();
                labelDisplay.text = labelText;
            }
            else if (labelField) // if labelField is not null or "", then this is a user-set value
            {
                try
                {
                    if (labelField in data && data[labelField] != null)
                    {
                        labelText = data[labelField];
                        if (!labelDisplay)
                            createLabelDisplay();
                        labelDisplay.text = labelText;
                    }
                    else
                    {
                        labelText = "";
                        if (!labelDisplay)
                            createLabelDisplay();
                        labelDisplay.text = labelText;
                    }
                }
                catch(e:Error)
                {
                    labelText = "";
                    if (!labelDisplay)
                        createLabelDisplay();
                    labelDisplay.text = labelText;
                }
            }
            else if (label && labelField === null) // if there's a label and labelField === null, then show label
            {
                labelText = label;
                if (!labelDisplay)
                    createLabelDisplay();
                labelDisplay.text = labelText;
            }
            else // if labelField === ""
            {
                // get rid of labelDisplay if present
                if (labelDisplay)
                    removeLabelDisplay();
            }
            
            invalidateSize();
            invalidateDisplayList();
        }
        
        if (iconNeedsDisplayObjectAssignment)
        {
            iconNeedsDisplayObjectAssignment = false;
            if (iconDisplay)
            {
                // try using this display object first
                if (iconDisplay.setSharedDisplayObject(this))
                {
                    iconDisplay.displayObjectSharingMode = DisplayObjectSharingMode.USES_SHARED_OBJECT;
                }
                else
                {
                    // if we can't use this as the display object, then let's see if 
                    // the icon already has and owns a display object
                    var ownsDisplayObject:Boolean = (iconDisplay.displayObjectSharingMode != DisplayObjectSharingMode.USES_SHARED_OBJECT);
                    
                    // If the element doesn't have a DisplayObject or it doesn't own
                    // the DisplayObject it currently has, then create a new one
                    var displayObject:DisplayObject = iconDisplay.displayObject;
                    if (!ownsDisplayObject || !displayObject)
                        displayObject = iconDisplay.createDisplayObject();
                    
                    // Add the display object as a child
                    // Check displayObject for null, some graphic elements
                    // may choose not to create a DisplayObject during this pass.
                    if (displayObject)
                        addChild(displayObject);
                    
                    iconDisplay.displayObjectSharingMode = DisplayObjectSharingMode.OWNS_UNSHARED_OBJECT;
                }
            }
                
        }
        
        if (iconNeedsValidateProperties)
        {
            iconNeedsDisplayObjectAssignment = false;
            if (iconDisplay)
                iconDisplay.validateProperties();
        }
    }
    
    /**
     *  @private
     */
    private function createLabelDisplay():void
    {
        // need to create it
        labelDisplay = StyleableTextField(createInFontContext(StyleableTextField));
        labelDisplay.styleName = this;
        labelDisplay.editable = false;
        labelDisplay.selectable = false;
        labelDisplay.multiline = false;
        labelDisplay.wordWrap = false;
        
        addChild(labelDisplay);
    }
    
    /**
     *  @private
     */
    private function removeLabelDisplay():void
    {
        removeChild(labelDisplay);
        labelDisplay = null;
    }
    
    /**
     *  @private
     */
    private function setIconDisplaySource(source:Object):void
    {
        var iconDelay:Number = getStyle("iconDelay");
        
        
        // if not a string or URL request (or null), load it up immediately
        var isExternalSource:Boolean = (source is String || source is URLRequest);
        
        // if null or iconDelay == 0, do it synchronously
        if (!isExternalSource || iconDelay == 0)
        {
            // stop any asynch operation:
            if (iconSetterDelayTimer)
            {
                loadingIconSource = null
                iconSetterDelayTimer.stop();
                iconSetterDelayTimer.reset();
            }
            
            // load it up
            iconDisplay.source = source;
            
            return;
        }
        
        // if it's the same source, don't cancel this load--let it continue 
        if (loadingIconSource == source)
            return;
        
        // At this point, we know we can cancel the old asynch operation 
        // since we're not going to use it anymore
        if (iconSetterDelayTimer)
        {
            loadingIconSource = null
            iconSetterDelayTimer.stop();
            iconSetterDelayTimer.reset();
        }
        
        // we know we're loading external content, check the cache first:
        var contentCache:ContentCache = iconContentLoader as ContentCache;
        if (contentCache)
        {
            if (contentCache.getCacheEntry(source))
            {
                iconDisplay.source = source;
                return;
            }
        }
        
        // otherwise, we need to rely on the timer
        if (!iconSetterDelayTimer)
        {
            iconSetterDelayTimer = new Timer(iconDelay, 1);
            iconSetterDelayTimer.addEventListener(TimerEvent.TIMER_COMPLETE, iconSetterDelayTimer_timerCompleteHandler);
        }
        
        // this is so we don't display the old data while we're loading
        // FIXME (rfrishbe): perhaps we should add an iconLoadingAsset (must be embedded) property?
        iconDisplay.source = null;
        loadingIconSource = source;
        
        iconSetterDelayTimer.start();
    }
    
    /**
     *  @private
     */
    private function iconSetterDelayTimer_timerCompleteHandler(event:TimerEvent):void
    {
        // if we're off-screen, don't do anything
        // when we get re-included, our data will be reset as well
        if (!includeInLayout)
            return;
        
        if (iconDisplay)
            iconDisplay.source = loadingIconSource;
        
        loadingIconSource = null;
    }
    
    /**
     *  @private
     */
    override public function validateSize(recursive:Boolean = false):void
    {
        // Since IGraphicElement is not ILayoutManagerClient, we need to make sure we
        // validate sizes of the elements, even in cases where recursive==false.
        
        // Validate element size
        if (iconNeedsValidateSize)
        {
            iconNeedsValidateSize = false;
            if (iconDisplay)
                iconDisplay.validateSize();
        }
        
        super.validateSize(recursive);
    }
    
    /**
     *  @private
     *  
     *  @langversion 3.0
     *  @playerversion Flash 10.2
     *  @playerversion AIR 2.0
     *  @productversion Flex 4.5
     */
    override public function setEstimatedSize(estimatedWidth:Number = NaN, 
                                              estimatedHeight:Number = NaN,
                                              invalidateSizeAllowed:Boolean = true):void
    {
        var oldcw:Number = this.estimatedWidth;
        var oldch:Number = this.estimatedHeight;
        
        super.setEstimatedSize(estimatedWidth, estimatedHeight, invalidateSizeAllowed);
        
        var sameWidth:Boolean = isNaN(estimatedWidth) && isNaN(oldcw) || estimatedWidth == oldcw;
        var sameHeight:Boolean = isNaN(estimatedHeight) && isNaN(oldch) || estimatedHeight == oldch;
        if (!(sameHeight && sameWidth))
        {
            if (!isNaN(explicitWidth) &&
                !isNaN(explicitHeight))
                return;
            
            if (invalidateSizeAllowed)
                invalidateSize();
        }
    }
    
    /**
     *  @private
     */
    override protected function measure():void
    {
        // don't call super.measure() because there's no need to do the work that's
        // in there--we do it all in here.
        //super.measure();
        
        // start them at 0, then go through icon, label, and decorator
        // and add to these
        var myMeasuredWidth:Number = 0;
        var myMeasuredHeight:Number = 0;
        var myMeasuredMinWidth:Number = 0;
        var myMeasuredMinHeight:Number = 0;
        
        // calculate padding and horizontal gap
        // verticalGap is already handled above when there's a label
        // and a message since that's the only place verticalGap matters.
        // if we handled verticalGap here, it might add it to the icon if 
        // the icon was the tallest item.
        var numHorizontalSections:int = 0;
        if (iconDisplay)
            numHorizontalSections++;
        
        if (decoratorDisplay)
            numHorizontalSections++;
        
        if (labelDisplay || messageDisplay)
            numHorizontalSections++;
        
        var paddingAndGapWidth:Number = getStyle("paddingLeft") + getStyle("paddingRight");
        if (numHorizontalSections > 0)
            paddingAndGapWidth += (getStyle("horizontalGap") * (numHorizontalSections - 1));
        
        var verticalGap:Number = (labelDisplay && messageDisplay) ? getStyle("verticalGap") : 0;
        var paddingHeight:Number = getStyle("paddingTop") + getStyle("paddingBottom");
        
        // Icon is on left
        var myIconWidth:Number = 0;
        var myIconHeight:Number = 0;
        if (iconDisplay)
        {
            myIconWidth = (isNaN(iconWidth) ? getElementPreferredWidth(iconDisplay) : iconWidth);
            myIconHeight = (isNaN(iconHeight) ? getElementPreferredHeight(iconDisplay) : iconHeight);
            
            myMeasuredWidth += myIconWidth;
            myMeasuredMinWidth += myIconWidth;
            myMeasuredHeight = Math.max(myMeasuredHeight, myIconHeight);
            myMeasuredMinHeight = Math.max(myMeasuredMinHeight, myIconHeight);
        }
        
        // Decorator is up next
        var decoratorWidth:Number = 0;
        var decoratorHeight:Number = 0;
        
        if (decoratorDisplay)
        {
            decoratorWidth = getElementPreferredWidth(decoratorDisplay);
            decoratorHeight = getElementPreferredHeight(decoratorDisplay);
            
            myMeasuredWidth += decoratorWidth;
            myMeasuredMinWidth += decoratorWidth;
            myMeasuredHeight = Math.max(myMeasuredHeight, decoratorHeight);
            myMeasuredMinHeight = Math.max(myMeasuredHeight, decoratorHeight);
        }
        
        // Text is aligned next to icon
        var labelWidth:Number = 0;
        var labelHeight:Number = 0;
        var messageWidth:Number = 0;
        var messageHeight:Number = 0;
        
        if (labelDisplay)
        {
            // reset text if it was truncated before.
            if (labelDisplay.isTruncated)
                labelDisplay.text = labelText;
            
            labelWidth = getElementPreferredWidth(labelDisplay);
            labelHeight = getElementPreferredHeight(labelDisplay);
        }
        
        if (messageDisplay)
        {
            // now we need to measure messageDisplay's height.  Unfortunately, this is tricky and 
            // is dependent on messageDisplay's width
            // if we have an estimated width, use it to calculate messageDisplay's width.  
            // Otherwise, we'll keep it the same width as it was before
            if (!isNaN(estimatedWidth))
                messageDisplay.width = estimatedWidth - paddingAndGapWidth - decoratorWidth - myIconWidth;
                
            messageWidth = getElementPreferredWidth(messageDisplay);
            messageHeight = getElementPreferredHeight(messageDisplay);
        }
        
        myMeasuredWidth += Math.max(labelWidth, messageWidth);
        myMeasuredHeight = Math.max(myMeasuredHeight, labelHeight + messageHeight + verticalGap);
        
        myMeasuredWidth += paddingAndGapWidth;
        myMeasuredMinWidth += paddingAndGapWidth;
        
        // verticalGap handled in label and message
        myMeasuredHeight += paddingHeight;
        myMeasuredMinHeight += paddingHeight;
        
        // now set the local variables to the member variables.  Make sure it means our
        // minimum height of 80
        measuredWidth = myMeasuredWidth
        measuredHeight = Math.max(80, myMeasuredHeight);
        
        measuredMinWidth = myMeasuredMinWidth;
        measuredMinHeight = Math.max(80, myMeasuredMinHeight);
    }
    
    /**
     *  @private
     *  We override the setLayoutBoundsSize to determine whether to perform
     *  text reflow. This is a convenient place, as the layout passes NaN
     *  for a dimension not constrained to the parent.
     */
    override public function setLayoutBoundsSize(width:Number,
                                                 height:Number,
                                                 postLayoutTransform:Boolean = true):void
    {
        var newEstimates:Boolean = false;
        var cw:Number = estimatedWidth;
        var ch:Number = estimatedHeight;
        var oldcw:Number = cw;
        var oldch:Number = ch;
        // we got lied to, probably the constraints weren't accurate or
        // couldn't be computed
        if (!isNaN(width))
        {
            if (isNaN(estimatedWidth) || width != estimatedWidth)
            {
                cw = width;
                newEstimates = true;
            }
        }
        // we got lied to, probably the constraints weren't accurate or
        // couldn't be computed
        if (!isNaN(height))
        {
            if (isNaN(estimatedHeight) || height != estimatedHeight)
            {
                ch = height;
                newEstimates = true;
            }
        }
        if (newEstimates)
        {
            setEstimatedSize(cw, ch);
            
            // re-measure with the new estimated size
            UIComponentGlobals.layoutManager.validateClient(this, true);
            
            // set estimated size back to what it was
            setEstimatedSize(oldcw, oldch, false);
        }
        
        super.setLayoutBoundsSize(width, height, postLayoutTransform);
    }
    
    /**
     *  @private
     *  If we invalidate display list, we need to redraw any graphic elements sharing 
     *  our display object since we call graphics.clear() in super.updateDisplayList()
     */
    override public function invalidateDisplayList():void
    {
        redrawRequested = true;
        super.invalidateDisplayList();
    }
    
    /**
     *  @private
     */
    override protected function layoutContents(unscaledWidth:Number,
                                               unscaledHeight:Number):void
    {
        // no need to call super.layoutContents() since we're changing how it happens here
        
        // start laying out our children now
        var iconWidth:Number = 0;
        var iconHeight:Number = 0;
        var decoratorWidth:Number = 0;
        var decoratorHeight:Number = 0;

        var paddingLeft:Number   = getStyle("paddingLeft");
        var paddingRight:Number  = getStyle("paddingRight");
        var paddingTop:Number    = getStyle("paddingTop");
        var paddingBottom:Number = getStyle("paddingBottom");
        var horizontalGap:Number = getStyle("horizontalGap");
        var verticalAlign:String = getStyle("verticalAlign");
        var verticalGap:Number   = (labelDisplay && messageDisplay) ? getStyle("verticalGap") : 0;

        var vAlign:Number;
        if (verticalAlign == "top")
            vAlign = 0;
        else if (verticalAlign == "bottom")
            vAlign = 1;
        else // if (verticalAlign == "middle")
            vAlign = 0.5;
        // made "middle" last even though it's most likely so it is the default and if someone 
        // types "center", then it will still vertically center itself.

        var viewWidth:Number  = unscaledWidth  - paddingLeft - paddingRight;
        var viewHeight:Number = unscaledHeight - paddingTop  - paddingBottom;
        
        // icon is on the left
        if (iconDisplay)
        {
            // set the icon's position and size
            setElementSize(iconDisplay, this.iconWidth, this.iconHeight);
            
            iconWidth = iconDisplay.getLayoutBoundsWidth();
            iconHeight = iconDisplay.getLayoutBoundsHeight();
            
            // if there's no messageDisplay, then use vAlign to position the icon.
            // otherwise, just position it at y = paddingTop
            var iconDisplayY:Number;
            if (!messageDisplay)
                iconDisplayY = Math.round(vAlign * (viewHeight - iconHeight)) + paddingTop;
            else
                iconDisplayY = paddingTop;
            
            setElementPosition(iconDisplay, paddingLeft, iconDisplayY);
        }
        
        // decorator is aligned next to icon
        if (decoratorDisplay)
        {
            decoratorWidth = getElementPreferredWidth(decoratorDisplay);
            decoratorHeight = getElementPreferredHeight(decoratorDisplay);

            setElementSize(decoratorDisplay, decoratorWidth, decoratorHeight);

            // decorator is always right aligned, vertically centered
            var decoratorY:Number = Math.round(0.5 * (viewHeight - decoratorHeight)) + paddingTop;
            setElementPosition(decoratorDisplay, unscaledWidth - paddingRight - decoratorWidth, decoratorY);
        }

        // Figure out how much space we have for label and message as well as the 
        // starting left position
        var labelComponentsViewWidth:Number = viewWidth - iconWidth - decoratorWidth;
        
        // don't forget the extra gap padding if these elements exist
        if (iconDisplay)
            labelComponentsViewWidth -= horizontalGap;
        if (decoratorDisplay)
            labelComponentsViewWidth -= horizontalGap;
        
        var labelComponentsX:Number = paddingLeft;
        if (iconDisplay)
            labelComponentsX += iconWidth + horizontalGap;
        
        // calculte the natural height for the label
        var labelTextHeight:Number = 0;
        
        if (labelDisplay && labelText != "")
        {
            // reset text if it was truncated before.
            if (labelDisplay.isTruncated)
                labelDisplay.text = labelText;
            
            // commit styles to make sure it uses updated look
            labelDisplay.commitStyles();
            
            labelTextHeight = getElementPreferredHeight(labelDisplay);
        }
        
        if (messageDisplay && messageText != "")
        {
            // commit styles to make sure it uses updated look
            messageDisplay.commitStyles();
        }

        // now size and position the elements, 3 different configurations we care about:
        // 1) label and message
        // 2) label only
        // 3) message only

        // label display goes on top
        // message display goes below

        var labelWidth:Number = 0;
        var labelHeight:Number = 0;
        var messageWidth:Number = 0;
        var messageHeight:Number = 0;

        if (labelDisplay)
        {
            // handle labelDisplay.  it can only be 1 line
            
            // width of label takes up rest of space
            // height only takes up what it needs so we can properly place the message
            // and make sure verticalAlign is operating on a correct value.
            labelWidth = Math.max(labelComponentsViewWidth, 0);
            labelHeight = Math.max(Math.min(viewHeight, labelTextHeight), 0);
            setElementSize(labelDisplay, labelWidth, labelHeight);
            
            // attempt to truncate text
            labelDisplay.truncateToFit();
        }

        if (messageDisplay)
        {
            // handle message
            messageWidth = Math.max(labelComponentsViewWidth, 0);
            messageHeight = Math.max(viewHeight - labelHeight - verticalGap, 0);
            
            setElementSize(messageDisplay, messageWidth, messageHeight);
            messageHeight = Math.max(0, Math.min(messageHeight, getElementPreferredHeight(messageDisplay)));
            
            // since it's multi-line, no need to truncate
            //if (messageDisplay.isTruncated)
            //    messageDisplay.text = messageText;
            //messageDisplay.truncateToFit();
        }

        // Position the text components now that we know all heights so we can respect verticalAlign style
        if (labelDisplay || messageDisplay)
        {
            var totalHeight:Number = labelHeight + messageHeight + verticalGap;
            var labelComponentsY:Number = Math.round(vAlign * (viewHeight - totalHeight)) + paddingTop;

            if (labelDisplay)
                setElementPosition(labelDisplay, labelComponentsX, labelComponentsY);

            if (messageDisplay)
                setElementPosition(messageDisplay, labelComponentsX, labelComponentsY + labelHeight + verticalGap);
        }
        
        // see if we have an icon that needs to be validated
        if (iconDisplay && 
            iconDisplay.displayObject is ISharedDisplayObject && 
            ISharedDisplayObject(iconDisplay.displayObject).redrawRequested)
        {
            ISharedDisplayObject(iconDisplay.displayObject).redrawRequested = false;
            iconDisplay.validateDisplayList();
        }
    }
    
}
    
}