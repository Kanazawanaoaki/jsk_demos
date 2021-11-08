#!/usr/bin/env roseus

(defun make-ih-stove-graph ()
  ;; (let (off on)
    (setq *ih-stove-graph* (instance graph :name 'ih-stove-graph))
    
    ;; def node
    (setq off (instance node :name 'off))
    (setq on (instance node :name 'on))
    (setq melting-fire (instance node :name 'melting-fire))
    (setq low-heat (instance node :name 'low-heat))
    (setq medium-heat (instance node :name 'medium-heat))
    (setq high-heat (instance node :name 'high-heat))
    (setq high-power (instance node :name 'high-power))
    
    ;; add node
    (send *ih-stove-graph* :add-node off)
    (send *ih-stove-graph* :add-node on)
    (send *ih-stove-graph* :add-node melting-fire)
    (send *ih-stove-graph* :add-node low-heat)
    (send *ih-stove-graph* :add-node medium-heat)
    (send *ih-stove-graph* :add-node high-heat)
    (send *ih-stove-graph* :add-node high-power)
    
    ;; add arc
    (send *ih-stove-graph* :add-arc-from-to off on)
    (send *ih-stove-graph* :add-arc-from-to on medium-heat)
    (send *ih-stove-graph* :add-arc-from-to melting-fire low-heat)
    (send *ih-stove-graph* :add-arc-from-to low-heat medium-heat)
    (send *ih-stove-graph* :add-arc-from-to medium-heat high-heat)
    (send *ih-stove-graph* :add-arc-from-to high-heat high-power)
    (send *ih-stove-graph* :add-arc-from-to high-power high-heat)
    (send *ih-stove-graph* :add-arc-from-to high-heat medium-heat)
    (send *ih-stove-graph* :add-arc-from-to medium-heat low-heat)
    (send *ih-stove-graph* :add-arc-from-to low-heat melting-fire)
    (send *ih-stove-graph* :add-arc-from-to melting-fire off)
    (send *ih-stove-graph* :add-arc-from-to low-heat off)
    (send *ih-stove-graph* :add-arc-from-to medium-heat off)
    (send *ih-stove-graph* :add-arc-from-to high-heat off)
    (send *ih-stove-graph* :add-arc-from-to high-power off)
    
    *ih-stove-graph*
    ;; )
  )

(defun view-graph ()
  (send *ih-stove-graph* :write-to-pdf "ih_stove.pdf")
  ;; (when (ros::get-param "~display_graph" "true")
  (piped-fork "xdg-open ih_stove.pdf"))
  )

;; (make-ih-stove-graph)
(setq *isg* (make-ih-stove-graph))

(warn "please run (view-graph) ~%")
  
