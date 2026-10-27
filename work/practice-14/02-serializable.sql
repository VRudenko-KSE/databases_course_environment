-- P14-2: staffing decision and retry. Schema: p14_serializable.
-- A1 -> B1 -> A2 -> B2 -> [B3 if B2 succeeded] -> B4 -> B5 -> B6 -> A3.

-- @block serial_A1 A
-- BEGIN ISOLATION LEVEL /* TODO SERIAL_MODE */;
-- SELECT count(*) AS on_duty FROM p14_serializable.invigilators
-- WHERE exam_id=1403 AND on_duty;
-- @endblock

-- @block serial_B1 B
-- BEGIN ISOLATION LEVEL /* TODO SERIAL_MODE */;
-- SELECT count(*) AS on_duty FROM p14_serializable.invigilators
-- WHERE exam_id=1403 AND on_duty;
-- @endblock

-- Both initial counts must finish before A2.
-- @block serial_A2 A
-- UPDATE p14_serializable.invigilators SET on_duty=false
-- WHERE exam_id=1403 AND staff_code='I-A' RETURNING staff_code,on_duty;
-- COMMIT;
-- @endblock

-- @block serial_B2 B
-- UPDATE p14_serializable.invigilators SET on_duty=false
-- WHERE exam_id=1403 AND staff_code='I-B' RETURNING staff_code,on_duty;
-- @endblock

-- If B2 errored, save the error and skip B3. Otherwise run B3 and save its error.
-- @block serial_B3 B
-- COMMIT;
-- @endblock

-- Clear the rejected attempt.
-- @block serial_B4 B
-- /* TODO CLEAR_ATTEMPT */
-- @endblock

-- Start a new transaction and read fresh data.
-- @block serial_B5 B
-- /* TODO RETRY_BEGIN */
-- SELECT count(*) AS on_duty FROM p14_serializable.invigilators
-- WHERE exam_id=1403 AND on_duty;
-- @endblock

-- Keep the UPDATE only if B5 permits removal; finish the transaction either way.
-- @block serial_B6 B
-- UPDATE p14_serializable.invigilators SET on_duty=false
-- WHERE exam_id=1403 AND staff_code='I-B' RETURNING staff_code,on_duty;
-- /* TODO RETRY_FINISH */
-- @endblock

-- @block serial_A3 A
-- SELECT staff_code,on_duty FROM p14_serializable.invigilators ORDER BY staff_code;
-- SELECT count(*) AS on_duty FROM p14_serializable.invigilators
-- WHERE exam_id=1403 AND on_duty;
-- @endblock
