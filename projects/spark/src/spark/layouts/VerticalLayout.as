////////////////////////////////////////////////////////////////////////////////
//
//  ADOBE SYSTEMS INCORPORATED
//  Copyright 2008 Adobe Systems Incorporated
//  All Rights Reserved.
//
//  NOTICE: Adobe permits you to use, modify, and distribute this file
//  in accordance with the terms of the license agreement accompanying it.
//
////////////////////////////////////////////////////////////////////////////////

package flex.layout
{
import flash.geom.Rectangle;

import flex.core.Group;
import flex.intf.ILayout;
import flex.intf.ILayoutItem;

import mx.containers.utilityClasses.Flex;


/**
 *  Documentation is not currently available.
 */
public class VerticalLayout implements ILayout
{
    include "../core/Version.as";
    
    //--------------------------------------------------------------------------
    //
    //  Class methods
    //
    //--------------------------------------------------------------------------

    private static function hasPercentWidth( layoutItem:ILayoutItem ):Boolean
    {
    	return !isNaN( layoutItem.percentSize.x );
    }
    
    private static function hasPercentHeight( layoutItem:ILayoutItem ):Boolean
    {
        return !isNaN( layoutItem.percentSize.y );
    }
    
    private static function calculatePercentWidth( layoutItem:ILayoutItem, width:Number ):Number
    {
    	var percentWidth:Number = LayoutItemHelper.pinBetween( layoutItem.percentSize.x * width,
    	                                                       layoutItem.minSize.x,
    	                                                       layoutItem.maxSize.x );
    	return percentWidth < width ? percentWidth : width;
    }
        
    //--------------------------------------------------------------------------
    //
    //  Constructor
    //
    //--------------------------------------------------------------------------

    /**
     *  Constructor. 
     */    
    public function VerticalLayout():void
    {
		super();
    }
    
    //--------------------------------------------------------------------------
    //
    //  Properties
    //
    //--------------------------------------------------------------------------

    private var _target:Group;
    
    public function get target():Group
    {
        return _target;
    }
    
    public function set target(value:Group):void
    {
        _target = value;
    }

    //----------------------------------
    //  gap
    //----------------------------------
    
    /**
     *  @private
     */
    private var _gap:int = 6;
    
    /**
     *  @private
     */
    private var gapChanged:Boolean = false;

    [Inspectable(category="General")]

    /**
     *  Vertical space between rows.
     * 
     *  @default 6
     */
    public function get gap():int
    {
        return _gap;
    }

    /**
     *  @private
     */
    public function set gap(value:int):void
    {
        if (_gap == value) return;

		_gap = value;
 	   	var layoutTarget:Group = target;
    	if (layoutTarget != null) 
    	{
			gapChanged = true;
        	layoutTarget.invalidateSize();
            layoutTarget.invalidateDisplayList();
    	}
    }
    
    //----------------------------------
    //  explicitRowCount
    //----------------------------------

    /**
     *  The row count requested by explicitly setting
     *  <code>rowCount</code>.
     */
    protected var explicitRowCount:int = -1;

    //----------------------------------
    //  rowCount
    //----------------------------------

    /**
     *  @private
     */
    private var _rowCount:int = -1;
    
    /**
     *  @private
     */
    private var rowCountChanged:Boolean = false;

    [Inspectable(category="General")]

    /**
     *  Number of rows to be displayed.
     *  If the height of the component has been explicitly set,
     *  this property might not have any effect.
     * 
     *  @default -1
     */
    public function get rowCount():int
    {
        return _rowCount;
    }

    /**
     *  @private
     */
    public function set rowCount(value:int):void
    {
        explicitRowCount = value;

        if (_rowCount != value)
        {
            setRowCount(value);
 		   	var layoutTarget:Group = target;
        	if (layoutTarget != null) 
        	{
        		rowCountChanged = true;
            	layoutTarget.invalidateSize();
	            layoutTarget.invalidateDisplayList();
        	}
        }
    }

    /**
     *  Sets the <code>rowCount</code> property without causing
     *  invalidation or setting the <code>explicitRowCount</code>
     *  property, which permanently locks in the number of rows.
     *
     *  @param v The row count.
     */
    protected function setRowCount(v:int):void
    {
        _rowCount = v;
    }

    //----------------------------------
    //  explicitRowHeight
    //----------------------------------

    /**
     *  The row height requested by explicitly setting
     *  <code>rowHeight</code>.
     */
    protected var explicitRowHeight:Number;

    //----------------------------------
    //  rowHeight
    //----------------------------------
    
    /**
     *  @private
     */
    private var _rowHeight:Number = 20;
    
    /**
     *  @private
     */
    private var rowHeightChanged:Boolean = false;

    [Inspectable(category="General")]

    /**
     *  The height of the rows in pixels.
     *  Unless the <code>variableRowHeight</code> property is
     *  <code>true</code>, all rows are the same height.  
     */
    public function get rowHeight():Number
    {
        return _rowHeight;
    }

    /**
     *  @private
     */
    public function set rowHeight(value:Number):void
    {
        explicitRowHeight = value;

        if (_rowHeight != value)
        {
            setRowHeight(value);
 		   	var layoutTarget:Group = target;
        	if (layoutTarget != null) 
        	{
        		rowHeightChanged = true;
            	layoutTarget.invalidateSize();
	            layoutTarget.invalidateDisplayList();
        	}
        }
    }

    /**
     *  Sets the <code>rowHeight</code> property without causing invalidation or 
     *  setting of <code>explicitRowHeight</code> which
     *  permanently locks in the height of the rows.
     *
     *  @param value The row height, in pixels.
     */
    protected function setRowHeight(value:Number):void
    {
        _rowHeight = value;
    }    


    //----------------------------------
    //  variableRowHeight
    //----------------------------------

    /**
     *  @private
     */
    private var _variableRowHeight:Boolean = true;

    [Inspectable(category="General")]

    /**
     *  @default true
     */
    public function get variableRowHeight():Boolean
    {
        return _variableRowHeight;
    }

    /**
     *  @private
     */
    public function set variableRowHeight(value:Boolean):void
    {
        if (value == _variableRowHeight) return;
        
        _variableRowHeight = value;
 		var layoutTarget:Group = target;
        if (layoutTarget != null) {
    		layoutTarget.invalidateSize();
        	layoutTarget.invalidateDisplayList();
        }
    }


    private function variableRowHeightMeasure(layoutTarget:Group):void
    {
        var minWidth:Number = 0;
        var minHeight:Number = 0;
        var preferredWidth:Number = 0;
        var preferredHeight:Number = 0;
        var visibleHeight:Number = 0;
        var visibleRows:uint = 0;
        var explicitRowCount:int = explicitRowCount;
         
        var count:uint = layoutTarget.numLayoutItems;
        var totalCount:uint = count; // How many items will be laid out
        for (var i:int = 0; i < count; i++)
        {
            var layoutItem:ILayoutItem = layoutTarget.getLayoutItemAt(i);
            if (!layoutItem || !layoutItem.includeInLayout)
            {
            	totalCount--;
                continue;
            }            

            preferredWidth = Math.max(preferredWidth, layoutItem.preferredSize.x);
            preferredHeight += layoutItem.preferredSize.y; 

            var itemMinWidth:Number = hasPercentWidth(layoutItem) ? layoutItem.minSize.x : layoutItem.preferredSize.x;
            var itemMinHeight:Number = hasPercentHeight(layoutItem) ? layoutItem.minSize.y : layoutItem.preferredSize.y;
            minWidth = Math.max(minWidth, itemMinWidth);
            minHeight += itemMinHeight;
            
            if ((explicitRowCount != -1) && (visibleRows < explicitRowCount)) 
            {
            	visibleHeight = preferredHeight;
            	visibleRows += 1;
            }
        }
        
        if (totalCount > 1)
        { 
            var gapSpace:Number = gap * (totalCount - 1);
            minHeight += gapSpace;
            preferredHeight += gapSpace; 
            visibleHeight += (visibleRows > 1) ? (gap * (visibleRows - 1)) : 0;
        }
        
        layoutTarget.measuredWidth = preferredWidth;
        layoutTarget.measuredHeight = (explicitRowCount == -1) ? preferredHeight : visibleHeight;

        layoutTarget.contentWidth = preferredWidth;
        layoutTarget.contentHeight = preferredHeight;

        layoutTarget.measuredMinWidth = minWidth; 
        layoutTarget.measuredMinHeight = minHeight;
    }
   
   
    private function fixedRowHeightMeasure(layoutTarget:Group):void
    {
        // TBD init rowHeight if explicitRowHeight isNaN
        var rows:uint = layoutTarget.numLayoutItems;
        var visibleRows:uint = (explicitRowCount == -1) ? rows : explicitRowCount;
        var contentHeight:Number = (rows * rowHeight) + ((rows > 1) ? (gap * (rows - 1)) : 0);
        var visibleHeight:Number = (visibleRows * rowHeight) + ((visibleRows > 1) ? (gap * (visibleRows - 1)) : 0);
        
        var columnWidth:Number = layoutTarget.explicitWidth;
        var minColumnWidth:Number = columnWidth;
        if (isNaN(columnWidth)) 
        {
			minColumnWidth = columnWidth = 0;
	        var count:uint = layoutTarget.numLayoutItems;
	        for (var i:int = 0; i < count; i++)
	        {
	            var layoutItem:ILayoutItem = layoutTarget.getLayoutItemAt(i);
	            if (!layoutItem || !layoutItem.includeInLayout) continue;
	            columnWidth = Math.max(columnWidth, layoutItem.preferredSize.x);
	            var itemMinWidth:Number = hasPercentWidth(layoutItem) ? layoutItem.minSize.x : layoutItem.preferredSize.x;
	            minColumnWidth = Math.max(minColumnWidth, itemMinWidth);
	        }
        }     
        
        layoutTarget.measuredWidth = columnWidth;
        layoutTarget.measuredHeight = visibleHeight;
        
        layoutTarget.contentWidth = columnWidth; 
        layoutTarget.contentHeight = contentHeight;

        layoutTarget.measuredMinWidth = minColumnWidth;
        layoutTarget.measuredMinHeight = rowHeight;
    }
    
    
    public function measure():void
    {
    	var layoutTarget:Group = target;
        if (!layoutTarget)
            return;
            
        if (variableRowHeight) 
        	variableRowHeightMeasure(layoutTarget);
        else 
        	fixedRowHeightMeasure(layoutTarget);

    }
    
    
    public function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
    {
    	var layoutTarget:Group = target; 
        if (!layoutTarget)
            return;
        
        // TODO EGeorgie: use vector
        var layoutItemArray:Array = new Array();
        var count:uint = layoutTarget.numLayoutItems;
        var totalCount:uint = count; // How many items will be laid out
        for (var i:int = 0; i < count; i++)
        {
            var layoutItem:ILayoutItem = layoutTarget.getLayoutItemAt(i);
            if (!layoutItem || !layoutItem.includeInLayout)
            {
            	totalCount--;
                continue;
            } 
            layoutItemArray.push(layoutItem);
        }

        var totalHeightToDistribute:Number = unscaledHeight;
        if (totalCount > 1)
            totalHeightToDistribute -= (totalCount - 1) * gap;

        distributeHeight(layoutItemArray, unscaledWidth, totalHeightToDistribute); 
                            
        // TODO EGeorgie: horizontalAlign
        var hAlign:Number = 0;
        
        // If rowCount wasn't set, then as the LayoutItems are positioned
        // we'll count how many rows fall within the layoutTarget's scrollRect
        var visibleRows:uint = 0;
        var minVisibleY:Number = layoutTarget.verticalScrollPosition;
        var maxVisibleY:Number = minVisibleY + unscaledHeight;
        
        // Finally, position the objects        
        var y:Number = 0;
        for each (var lo:ILayoutItem in layoutItemArray)
        {
            var x:Number = (unscaledWidth - lo.actualSize.x) * hAlign;
            lo.setActualPosition(x, y);
            if (!variableRowHeight)
                lo.setActualSize(lo.actualSize.x, rowHeight);
            var dy:Number = lo.actualSize.y;
            if ((explicitRowCount == -1) && (y < maxVisibleY) && ((y + dy) > minVisibleY)) 
            	visibleRows += 1;
            y += dy + gap;
        }
        if (explicitRowCount == -1) 
        	setRowCount(visibleRows);

        BasicLayout.setScrollRect(layoutTarget, unscaledWidth, unscaledHeight);
    }
    
    
    /**
     *  This function sets the height of each child
     *  so that the heights add up to <code>height</code>. 
     *  Each child is set to its preferred height
     *  if its percentHeight is zero.
     *  If its percentHeight is a positive number,
     *  the child grows (or shrinks) to consume its
     *  share of extra space.
     *  
     *  The return value is any extra space that's left over
     *  after growing all children to their maxHeight.
     */
    public function distributeHeight(layoutItemArray:Array,
                                     width:Number,
                                     height:Number):Number
    {
        var spaceToDistribute:Number = height;
        var totalPercentHeight:Number = 0;
        var childInfoArray:Array = [];
        var childInfo:LayoutItemFlexChildInfo;
        var newWidth:Number;
        
        // If the child is flexible, store information about it in the
        // childInfoArray. For non-flexible children, just set the child's
        // width and height immediately.
        for each (var layoutItem:ILayoutItem in layoutItemArray)
        {
            if (hasPercentHeight(layoutItem))
            {
                totalPercentHeight += layoutItem.percentSize.y;

                childInfo = new LayoutItemFlexChildInfo();
                childInfo.layoutItem = layoutItem;
                childInfo.percent    = layoutItem.percentSize.y * 100;
                childInfo.min        = layoutItem.minSize.y;
                childInfo.max        = layoutItem.maxSize.y;
                
                childInfoArray.push(childInfo);                
            }
            else
            {
                newWidth = NaN;
                if (hasPercentWidth(layoutItem))
                   newWidth = calculatePercentWidth(layoutItem, width);
                
                layoutItem.setActualSize(newWidth, NaN);
                spaceToDistribute -= layoutItem.actualSize.y;
            } 
        }

        // Distribute the extra space among the flexible children
        if (totalPercentHeight)
        {
            totalPercentHeight *= 100;
            spaceToDistribute = Flex.flexChildrenProportionally(height,
                                                                spaceToDistribute,
                                                                totalPercentHeight,
                                                                childInfoArray);
            for each (childInfo in childInfoArray)
            {
            	newWidth = NaN;
            	if (hasPercentWidth(childInfo.layoutItem))
            	   newWidth = calculatePercentWidth(childInfo.layoutItem, width);

                childInfo.layoutItem.setActualSize(newWidth, childInfo.size);
            }
        }
        return spaceToDistribute;
    }
}
}

[ExcludeClass]

import flex.intf.ILayoutItem;
import mx.containers.utilityClasses.FlexChildInfo;

class LayoutItemFlexChildInfo extends FlexChildInfo
{
    public var layoutItem:ILayoutItem;	
}
