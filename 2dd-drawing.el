;;; 2dd-drawing.el --- 2dd drawing object -*- lexical-binding: t -*-

;;; Commentary:
;; A 2dd drawing is an object that can be drawn in a 2dd-canvas.

;;; Code:
(require 'eieio)
(require '2dd-canvas)
(require '2dd-viewport)

(defclass 2dd-drawing ()
  ((_containment :initarg :containment
                 :reader 2dd-containment
                 :writer 2dd-set-containment
                 :initform 'captive
                 :type symbolp
                 :documentation "Containment must be one of (captive, free, semicaptive)")
   (_geometry :initarg :geometry
              :initform nil
              :writer 2dd-set-geometry
              :reader 2dd-geometry
              :documentation "The 2dg object backing this drawing"))
  :abstract t
  :documentation "This is a thing which can be drawn.  A rectangle, an arrow, a label, etc.")
(cl-defmethod 2dd-set-containment :before ((this 2dd-drawing) value)
  "Set the containment flag for THIS to VALUE after validation."
  (unless (memq value '(captive free semicaptive))
    (error "Invalid containment value: %s, must be one of (captive, free, semicaptive)"
           value)))
(cl-defgeneric 2dd-num-edit-idxs ((drawing 2dd-drawing))
  "How many edit idx points are there for this DRAWING.  It may be zero")
(cl-defgeneric 2dd-edit-idx-point ((drawing 2dd-drawing) (idx integer))
  "Get the 2dg-point location of the given edit IDX in DRAWING.

May return nil or error if idx is invalid.")
(cl-defgeneric 2dd-edit-idx-points ((drawing 2dd-drawing))
  "Get an ordered list of all the edit-idx points for this DRAWING.")
(cl-defgeneric 2dd-build-move-edited ((drawing 2dd-drawing) (move-vector 2dg-point) (viewport 2dd-viewport))
  ;; TODO - remove viewport from this, then from all methods.
  "Build a drawing based off moving DRAWING by MOVE-VECTOR.

This should only build a new drawing and return it (if possible)
and should not mutate anything.")
(cl-defgeneric 2dd-build-hint ((drawing 2dd-drawing) (parent-canvas 2dd-inner-canvas))
  "Given a DRAWING and PARENT-CANVAS generate a drawing 'hint'.

A drawing 'hint' is something that captures the intent of the
drawing but not the exact pixels.  Something like box-on-the-left
instead of an exact set of pixels/segments.  It may or may not be
relative to the parent-canvas.")
(cl-defgeneric 2dd-build-simplified ((drawing 2dd-drawing) (viewport 2dd-viewport))
  "Attempt to build a simplified DRAWING as seen by human eyes in VIEWPORT.

VIEWPORT is used to establish how agressive the simplification can be.")
(cl-defgeneric 2dd-inner-canvas-p ((drawing 2dd-drawing))
  "Return non-nil if this drawing has an inner-canvas.

Having an inner-canvas indicates that a drawing has space within
it to hold other drawings.")
(cl-defgeneric 2dd-render ((drawing 2dd-drawing) scratch x-transformer y-transformer &rest arg)
  "Render DRAWING to SCRATCH buffer using X-TRANSFORMER and Y-TRANSFORMER.

ARG can be used to pass in additional info to any rendering function.

Overridable method for ecah drawing to render itself."
  (error "Unable to render drawing of type %s"
         (eieio-object-class-name drawing)))
(cl-defmethod 2dd-num-edit-idxs ((drawing 2dd-drawing))
  "Non-editable drawings always have zero edit indices."
  0)
(cl-defmethod 2dd-edit-idx-point ((drawing 2dd-drawing) (idx integer))
  "Non-editable drawings always error when being asked for an edit idx point."
  (error "Non-editable drawings do not have edit idxs"))
(cl-defmethod 2dd-edit-idx-points ((drawing 2dd-drawing))
  "Non-editable drawings do not have any points."
  nil)
(cl-defmethod 2dd-inner-canvas-p ((drawing 2dd-drawing))
  "Return non-nil if this drawing has an inner-canvas.

By default, drawings do not have inner-canvases."
  nil)

(defclass 2dd-editable-drawing (2dd-drawing)
  ((_edit-idx :initarg :edit-idx
              :reader 2dd-get-edit-idx
              :writer 2dd-set-edit-idx
              :initform nil
              :type (or null integer)
              :documentation "Currently selected edit idx of the
              drawing, if any.  May be nil.  Edit idxs start at
              zero and count up."))
  :abstract t
  :documentation "A drawing which can have its shape edited.")
(cl-defgeneric 2dd-build-idx-edited ((drawing 2dd-editable-drawing) (edit-idx integer) (move-vector 2dg-point) (viewport 2dd-viewport))
  "Build a drawing based off moving EDIT-IDX of DRAWING by MOVE-VECTOR.

This should only build a new drawing and return it (if possible)
and should not mutate anything.")

(defclass 2dd-with-label ()
  ((_label :initarg :label
           :initform nil
           :reader 2dd-get-label
           :writer 2dd-set-label
           :type (or null string)))
  :abstract t
  :documentation "A mixin class to give drawings a single string label.")

(defclass 2dd-with-inner-canvas ()
  ((_padding-horizontal :initarg :padding-horizontal
                        :reader 2dd-padding-horizontal
                        :writer 2dd-set-padding-horizontal
                        :initform 0.0
                        :type float)
   (_padding-vertical :initarg :padding-vertical
                       :reader 2dd-padding-vertical
                       :writer 2dd-set-padding-vertical
                       :initform 0.0
                       :type float))
  :abstract t
  :documentation "When a drawing has an inner canvas this class holds the current plotting information relevant to child drawings.")
(cl-defmethod 2dd-has-inner-canvas-p ((drawing-with-inner 2dd-with-inner-canvas))
  "Drawings declared to have an inner canavs will return 't here."
  t)
(cl-defgeneric 2dd-get-inner-canvas ((drawing-with-inner 2dd-with-inner-canvas))
  "Return the current inner canvas of DRAWING-WITH-INNER.")
(cl-defmethod 2dd-get-inner-canvas ((drawing-with-inner 2dd-with-inner-canvas))
  "Return the current inner canvas of DRAWING-WITH-INNER."
  (error "Must implement 2dd-get-inner-canvas for %s"
         (eieio-object-class-name drawing-with-inner)))
(cl-defmethod 2dd-set-padding ((drawing 2dd-with-inner-canvas) (padding-horizontal number) (padding-vertical number))
  "Set PADDING-HORIZONTAL and PADDING-VERTICAL on this DRAWING."
  (2dd-set-padding-horizontal drawing (float padding-horizontal))
  (2dd-set-padding-vertical drawing (float padding-vertical)))


(provide '2dd-drawing)
;;; 2dd-drawing.el ends here
