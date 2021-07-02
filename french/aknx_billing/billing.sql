CREATE TABLE `billing` (
  `id` int(11) NOT NULL,
  `identifier` varchar(255) NOT NULL,
  `sender_billing` varchar(255) NOT NULL,
  `billing_type` varchar(50) NOT NULL,
  `target_type` varchar(255) NOT NULL,
  `billing_name` varchar(255) NOT NULL,
  `amount` int(11) NOT NULL,
  `date` varchar(255) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

ALTER TABLE `billing`
  ADD PRIMARY KEY (`id`);